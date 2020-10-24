#!/bin/sh
# ######################################################################
#  PACKAGE INSTALLER - SCRIPT DE DESINSTALACAO BANCO - MIGRACAO
# ######################################################################

# TRATAMENTO DE ARGUMENTOS DO SCRIPT
GLO_SCRIPT_ARGUMENTS=$@
GLO_INSTALL_OPERATION=$(echo $1 | tr [:lower:] [:upper:])



# ######################################################################
# INICIALIZACAO, CARREGAMENTO DE SCRIPTS, VARIAVEIS GLOBAIS
init() {
	# variavel utilizada por todo o processo de instalacao  
	export GLO_PACKAGE_DIR=`pwd`
	echo ""; echo ""; echo "";
	echo "[INFO] Preparando os arquivos..."	
	# lib
	dos2unix $GLO_PACKAGE_DIR/scripts/libs/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/libs/*.sh
	
	# --- carrega as libraries
	source $GLO_PACKAGE_DIR/scripts/libs/common_lib.sh
	source $GLO_PACKAGE_DIR/scripts/libs/core_lib.sh


	# ===== declaracao das variaveis globais
	GLO_TIMESTAMP=`date +"%Y%m%d%H%M%S"`                                        

	GLO_LOGFILE=$GLO_PACKAGE_DIR/logs/uninstall_migration_database_"$GLO_TIMESTAMP".log                    
	GLO_INSTALL_OPERATION_START="START"
	GLO_INSTALL_OPERATION_FORCE="FORCE"
		
	# outras variáveis                                                      
	export NLS_LANG=PORTUGUESE_BRAZIL.WE8MSWIN1252   

	
	# ===== VARIAVEIS GLOBAIS OBRIGATORIAS PARA AS LIBRARIES
	#BACKUPDIR=$GLO_PACKAGE_DIR/backup
	#GLO_BACKUPDIR=backup
	#UNINSTALL_FILE=$GLO_PACKAGE_DIR/backup/uninstall_list_files.txt
	#GLO_UNINSTALL_FILE=backup/uninstall_list_files.txt
	GLO_TMPDIR=tmp

	GLO_SYSTEM_FILE=$SYSTEM_PATH/environment.cfg
	GLO_TRUE=0
	GLO_FALSE=1
	GLO_SUCCESS=0
	GLO_ERROR=1
	
	GLO_STATUSCMD=$GLO_SUCCESS

	GLO_NUM_GLO_STATUSCMDERROR=0   # contador de erros

	# === VALIDACAO DA INICIALIZACAO
	load_VarInstallerProperties
	isValid_Var_SystemFile	||  exit $GLO_ERROR
	validateParameters	||  exit $GLO_ERROR
	
	# headerInfo
	load_db_schemas
}


# ##################################################################
# 
checkLogUninstallation(){
	echo ""
	myEcho 0 info S "Por favor, verifique o log '$GLO_LOGFILE' para detalhes da desinstalacao." 
	checkLog "$GLO_LOGFILE"
}



# ##################################################################
# DECLARA VARIAVEIS GLOBAIS, CARREGANDO AS CONFIGURACOES DOS SCHEMAS DO ARQUIVO ENVIRONMENT.CFG
load_db_schemas() {
	# ====== ENGINE
	DBEG_USER_USER_CLI=`cat $GLO_SYSTEM_FILE     | grep "db.engine.user.user_cli=" | awk -F "=" {'print $2'}`
	DBEG_PASSWORD_USER_CLI=`cat $GLO_SYSTEM_FILE | grep "db.engine.password.user_cli=" | awk -F "=" {'print $2'}`
	DBEG_SERVICE_NAME=`cat $GLO_SYSTEM_FILE     | grep "db.engine.service.name=" | awk -F "=" {'print $2'}`
}



# ######################################################################
doUninstall() {
	echo ""
	#myEcho 0 info T2 "Executando scripts de desinstalacao - Integracao (USER_SOL). Aguarde..."
	#uninstall_db_user_sol

}


# ###########################
# DESINSTALACAO NO BANCO USER_CLI - PREVALIDACAO
# RETORNA TRUE SE PASSOU NA VALIDACAO
uninstall_db_user_engine_prevalidation_OK() {
	return 0
}
	
	
# ###########################
# DESINSTALACAO NO BANCO USER_CLI
uninstall_db_user_engine() {
	
	#if uninstall_db_user_engine_prevalidation_OK  ||  [[ "$GLO_INSTALL_OPERATION" == "$GLO_INSTALL_OPERATION_FORCE" ]] ; then
	if uninstall_db_user_engine_prevalidation_OK ; then
		
		uninstall_db_user_engine_passo1
	else
		echo 
		# myEcho 0 error S "Validacao de seguranca: interrompido pois nao existe tabela SCH_TASK_BACKUP. Para migrar em modo forcado use o parametro $GLO_INSTALL_OPERATION_FORCE"
		myEcho 0 error S "Validacao de seguranca: desinstalacao interrompida pois nao existe tabela a restaurar SCH_TASK_BACKUP."
		
		return 1
	fi 
}


# ###########################
# DESINSTALACAO NO BANCO USER_CLI - PASSO 1
uninstall_db_user_engine_passo1() {
	# dados da conexao
	USER=$DBEG_USER_USER_CLI
	PASS=$DBEG_PASSWORD_USER_CLI
	SERVICE=$DBEG_SERVICE_NAME

	OLDDIR=`pwd`

	# -- start - customized actions for package 1.13.x
	doSpecificOperations {INTEGRATION_PRD}      "TOTAL_OF_ENGINES=25"
    doSpecificOperations {HML}                  "TOTAL_OF_ENGINES=2"
	doSpecificOperations {INTEGRATION_PT}       "TOTAL_OF_ENGINES=2"
	# -- end
	
	cd $GLO_PACKAGE_DIR/scripts/migracao/src_produto/db/migration/mi

	echo "==================================================="
	myEcho 0 info S "Conectando-se a '$SERVICE' usuario '$USER'"

	sqlplus -s $USER/$PASS@$SERVICE <<EOF
	-- SET ECHO ON
	set serveroutput on
	def USER_USER_CLI = $USER
	def TB_USER_HST = $DBEG_TABLESPACE_HST
	def TB_USER_HST_IDX = $DBEG_TABLESPACE_HST_IDX
	def TB_USER_CLI = $DBEG_TABLESPACE_CLI	
	def TB_USER_CLI_IDX = $DBEG_TABLESPACE_CLI_IDX
		
	-- da instalacao
	def db_cli_schema = $USER
	def db_cli_tbs_exec = $DBEG_TABLESPACE_CLI
	def db_cli_tbs_exec_idx = $DBEG_TABLESPACE_CLI_IDX
	def db_cli_num_engines = $TOTAL_OF_ENGINES
		
	-- do script de rollback
	DEFINE db_cli_tbs_exec				= '&&db_cli_tbs_exec'
	
	prompt
	@3.4.11-3.5.0-downgrade.sql

	quit
EOF
	cd $OLDDIR
}



# ###########################
# VALIDACAO DOS PARAMETROS DO SCRIPT
validateParameters() {
	# if [[ "$GLO_INSTALL_OPERATION" != "$GLO_INSTALL_OPERATION_START" && "$GLO_INSTALL_OPERATION" != "$GLO_INSTALL_OPERATION_FORCE" ]] ; then
	if [[ "$GLO_INSTALL_OPERATION" != "$GLO_INSTALL_OPERATION_START" ]] ; then

		echo "[ERROR] Parametro invalido: $GLO_INSTALL_OPERATION"
		echo "[INFO] Parametros validos:"
		echo "[INFO]    start - inicia desinstalacao"
		# echo "[INFO]    force - inicia em modo forcado"
		
		return 1
	fi 
}


# ######################################################################
# ROTINA PRINCIPAL - CONTINUACAO (LOG ATIVADO)
mainWrapper() {
	headerInfo
	myEcho 0 info T1 "[database] Desinstalacao iniciada..."

	convertFiles  "scripts/migracao" #|  listEchoInfo

	doUninstall
	
	echo ""
	myEcho 0 info S "[database] Desinstalacao finalizada"
}



# ######################################################################
# ROTINA PRINCIPAL
main() {
	init   &&   mainWrapper  2>&1  |  tee -a $GLO_LOGFILE
	removeColorCodes "$GLO_LOGFILE"
	checkLogUninstallation
}


main