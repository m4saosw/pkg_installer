#!/bin/sh
# ######################################################################
#  PACKAGE INSTALLER - SCRIPT DE DESINSTALACAO  SO/BANCO
# ######################################################################

# TRATAMENTO DE ARGUMENTOS DO SCRIPT
GLO_SCRIPT_ARGUMENTS=$@


# ######################################################################
# INICIALIZACAO, CARREGAMENTO DE SCRIPTS, VARIAVEIS GLOBAIS
init() {
	# variavel utilizada por todo o processo de instalacao  
	export GLO_PACKAGE_DIR=`pwd`

	prepare
	
	# --- carrega as libraries
	source $GLO_PACKAGE_DIR/scripts/libs/common_lib.sh
	source $GLO_PACKAGE_DIR/scripts/libs/core_lib.sh


	# ===== declaracao das variaveis globais
	GLO_TIMESTAMP=`date +"%Y%m%d%H%M%S"`                                        
	GLO_HOSTS_INSTALLATION_DATABASE="hostdatabase1 hostdatabase2"	

	GLO_LOGFILE=$GLO_PACKAGE_DIR/logs/uninstall_so_"$GLO_TIMESTAMP".log                    
	GLO_LOGFILE_DATABASE=$GLO_PACKAGE_DIR/logs/uninstall_database_"$GLO_TIMESTAMP".log
	#GLO_LOGFILE_BACKUP=$GLO_PACKAGE_DIR/logs/backup_"$GLO_TIMESTAMP".log  

	#GLO_INSTALL_OPERATION_BACKUP="BACKUP"
	#GLO_INSTALL_OPERATION_START="START"
	#GLO_INSTALL_OPERATION_VALIDATE="VALIDATE"
		
	# outras variáveis                                                      
	export NLS_LANG=PORTUGUESE_BRAZIL.WE8MSWIN1252   

	
	# ===== VARIAVEIS GLOBAIS OBRIGATORIAS PARA AS LIBRARIES
	GLO_BACKUPDIR=backup
	GLO_UNINSTALL_FILE=backup/uninstall_list_files.txt
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
}



# ######################################################################
prepare() {
	echo ""; echo ""; echo "";
	echo "[INFO] Preparando os arquivos..."
	
	# realiza tratamentos nos arquivos
	dos2unix $GLO_PACKAGE_DIR/scripts/libs/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/libs/*.sh
	
	dos2unix $GLO_PACKAGE_DIR/scripts/so/uninstall_so_routines.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/so/uninstall_so_routines.sh
}	



# ######################################################################
# inicia o processo de desinstalacao
uninstallSO() {
	local result=$GLO_SUCCESS
	myEcho 0 info T1 "Iniciando - S.O..."
	
	# loga a saida (padrao e erro) em arquivo
	# obs: utilizando source as variaveis serao compartilhadas entre os scripts
	source $GLO_PACKAGE_DIR/scripts/so/uninstall_so_routines.sh  $GLO_TIMESTAMP  2>&1  |  tee -a $GLO_LOGFILE
	result=$?
	
	removeColorCodes $GLO_LOGFILE
	
	echo ""
	echo "[INFO] Por favor, verifique o log '$GLO_LOGFILE'"
	checkLog $GLO_LOGFILE
	
	return $result
}


# ######################################################################
# inicia o processo de desinstalacao
uninstallDatabase() {
	local result=$GLO_SUCCESS
	myEcho 0 info T1 "Iniciando - Banco de Dados..."

	#--- TODO - refatorar esta estrutura
	#--- FAZ VALIDACAO SE O HOST CORRENTE E DE BANCO DE DADOS
	local hostValido=$GLO_ERROR
	for hostList in $GLO_HOSTS_INSTALLATION_DATABASE; do
		
		if isCurrentHost "$hostList"; then
			hostValido=$GLO_SUCCESS
		fi
	done
	
	if [[ $hostValido == $GLO_SUCCESS ]]; then
		
		# trata os arquivos de instalacao
		echo "[INFO] Preparando os arquivos..."	
		dos2unix $GLO_PACKAGE_DIR/scripts/database/uninstall_database_routines.sh
		chmod 755 $GLO_PACKAGE_DIR/scripts/database/uninstall_database_routines.sh
		
		
		# loga a saida (padrao e erro) em arquivo
		source $GLO_PACKAGE_DIR/scripts/database/uninstall_database_routines.sh  $GLO_TIMESTAMP  2>&1  |  tee -a $GLO_LOGFILE_DATABASE
		result=${PIPESTATUS[0]}    # quero somente o exit status do install_so_routines.sh
		removeColorCodes "$GLO_LOGFILE_DATABASE"
		
		sed -i '/database/d' control

		echo ""
		echo "[INFO] Por favor, verifique o log '$GLO_LOGFILE_DATABASE'"
		checkLog $GLO_LOGFILE_DATABASE
	else
		myEcho 0 warn S "Desinstalacao de Banco de Dados nao realizada no host '$( getCurrentHostName)'."		
	fi
	
	return $result
}


# ######################################################################
controlUninstallation() {
	local FIRST_INSTALLATION="firstInstallation"
	local INSTALLATION_MADE="installation"
	local UNINSTALLATION_MADE="remotion"
	local FIRST_INSTALLATION_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $FIRST_INSTALLATION | wc -l`
	local UNINSTALLATION_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $UNINSTALLATION_MADE | wc -l`
	local TRUE=1
	
	if [ ! $FIRST_INSTALLATION_VALIDATION == $TRUE ];then
		echo ""
		myEcho 0 warn S "A desinstalacao sera abortada, pois esse pacote nao foi instalado no ambiente."
		exit 1
	fi
	
	if [ ! $UNINSTALLATION_VALIDATION == $TRUE ];then
		sed -i "$ a $UNINSTALLATION_MADE" $GLO_PACKAGE_DIR/control
		sed -i "/$INSTALLATION_MADE/d" $GLO_PACKAGE_DIR/control
	else
		echo ""
		myEcho 0 warn S "A desinstalacao sera abortada, pois a mesma ja foi realizada."
		exit 1
	fi
}


# ######################################################################
# rotina principal
main() {
	init
	
	# controla a desinstalacao
	#controlUninstallation
		
	uninstallSO  &&  uninstallDatabase
}



main