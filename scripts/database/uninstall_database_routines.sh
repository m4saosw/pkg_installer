#!/bin/sh
############################################
#  SCRIPT DE DESDESINSTALACAO  DATABASE
############################################

############################ TRATAMENTO DE ARGUMENTOS DO SCRIPT ############################
# impede o script ser executado diretamente                             
if [ "$1" == "" ]; then                                                 
	echo "[ERROR] Este script nao pode ser chamado diretamente"
	exit 1                                                           
fi




######################################################################
# INICIALIZACAO, CARREGAMENTO DE SCRIPTS, VARIAVEIS GLOBAIS
init() {
	headerInfo

	#load_VarInstallerProperties
	#isValid_Var_SystemFile	||  exit $GLO_ERROR		
	load_db_schemas
}


# ##################################################################
# DECLARA VARIAVEIS GLOBAIS, CARREGANDO AS CONFIGURACOES DOS SCHEMAS DO ARQUIVO ENVIRONMENT.CFG
load_db_schemas() {
	# ====== product1
	DBAP_USER_PRODUCT_CFG=`cat $GLO_SYSTEM_FILE     | grep "db.product1.user.PRODUCT_CFG=" | awk -F "=" {'print $2'}`
	DBAP_PASSWORD_PRODUCT_CFG=`cat $GLO_SYSTEM_FILE | grep "db.product1.password.PRODUCT_CFG=" | awk -F "=" {'print $2'}`
	DBAP_SERVICE_NAME=`cat $GLO_SYSTEM_FILE     | grep "db.product1.service.name=" | awk -F "=" {'print $2'}`

}


# ######################################################################
convertFiles() {
	echo ""
	myEcho 0 info S "Convertendo arquivos (dos2unix)..."

	find -name '*.sql'  		-type f  -exec  dos2unix  -k {} \;
}


# ######################################################################
doUninstall() {
	echo ""
	myEcho 0 info T2 "Executando scripts de desinstalacao - Integracao (user_apresent1). Aguarde..."
	uninstall_db_user_apresent1
	
	# adicionar outros schemas se necessario

}


# ###########################
# DESINSTALACAO NO BANCO user_apresent1
uninstall_db_user_apresent1() {
	# dados da conexao
	USER=$DBAP_USER_PRODUCT_CFG
	PASS=$DBAP_PASSWORD_PRODUCT_CFG
	SERVICE=$DBAP_SERVICE_NAME

	OLDDIR=`pwd`

	cd $GLO_PACKAGE_DIR/scripts/database/apresentation/user_apresent1

	echo "==================================================="
	myEcho 0 info S "Conectando-se a '$SERVICE' usuario '$USER'"

	sqlplus -s $USER/$PASS@$SERVICE <<EOF
SET ECHO ON
def USER_PRODUCT_CFG = $USER
prompt
prompt [info] ============= Executando user_apresent1.sql
@user_apresent1.sql

quit
EOF
	cd $OLDDIR
}






# ######################################################################
# ROTINA PRINCIPAL
main() {
	init
	
	myEcho 0 info T1 "[database] Desinstalacao iniciada..."
	
	convertFiles  #|  listEchoInfo

	doUninstall
	
	echo ""
	myEcho 0 info S "[database] Desinstalacao finalizada"
}


main
return $?