#!/bin/sh
############################################
#  SCRIPT DE INSTALACAO  DATABASE
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
	# ====== product
	DBAP_USER_PRODUCT_CFG=`cat $GLO_SYSTEM_FILE     | grep "db.product.user.PRODUCT_CFG=" | awk -F "=" {'print $2'}`
	DBAP_PASSWORD_PRODUCT_CFG=`cat $GLO_SYSTEM_FILE | grep "db.product.password.PRODUCT_CFG=" | awk -F "=" {'print $2'}`
	DBAP_SERVICE_NAME=`cat $GLO_SYSTEM_FILE     | grep "db.product.service.name=" | awk -F "=" {'print $2'}`
}


# ######################################################################
convertFiles() {
	echo ""
	myEcho 0 info S "Convertendo arquivos (dos2unix)..."

	find -name '*.sql'  		-type f  -exec  dos2unix  -k {} \;
}


# ######################################################################
doInstall() {
	
	echo ""
	myEcho 0 info T2 "Executando scripts de instalacao - product (PRODUCT_CFG). Aguarde..."
	install_db_PRODUCT_CFG
	
	# adicionar outros schemas

	
	
}


# ###########################
# INSTALACAO NO BANCO PRODUCT_CFG
install_db_PRODUCT_CFG() {
	# dados da conexao
	USER=$DBAP_USER_PRODUCT_CFG
	PASS=$DBAP_PASSWORD_PRODUCT_CFG
	SERVICE=$DBAP_SERVICE_NAME

	OLDDIR=`pwd`

	cd $GLO_PACKAGE_DIR/scripts/database/apresentation/PRODUCT_CFG

	echo "==================================================="
	myEcho 0 info S "Conectando-se a '$SERVICE' usuario '$USER'"

	sqlplus -s $USER/$PASS@$SERVICE <<EOF
SET ECHO ON
def USER_PRODUCT_CFG = $USER

prompt
prompt [info] ============= Executando install_PRODUCT_CFG.sql
@install_PRODUCT_CFG.sql

quit
EOF
	cd $OLDDIR
}





# ######################################################################
# ROTINA PRINCIPAL
main() {
	init
	
	myEcho 0 info T1 "[database] Instalacao iniciada..."
	
	convertFiles  #|  listEchoInfo

	doInstall
	
	echo ""
	myEcho 0 info S "[database] Instalacao finalizada"
}


main
return $?