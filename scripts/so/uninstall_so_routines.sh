#!/bin/sh
#############################################################################
# INSTALLER PACKAGE
# SCRIPT DE DESINSTALACAO S.O.
#############################################################################

############################ TRATAMENTO DE ARGUMENTOS DO SCRIPT ############################
# impede o script ser executado diretamente                             
if [ "$1" == "" ]; then                                                 
	echo "[ERROR] Este script nao pode ser chamado diretamente"
	exit 1                                                           
fi




#######################################################################
# INICIALIZACAO, CARREGAMENTO DE SCRIPTS, VARIAVEIS GLOBAIS
init() {
	headerInfo

	#load_VarInstallerProperties
	#isValid_Var_SystemFile	||  exit $GLO_ERROR
	checkBackupDir
}		


# ######################################################################
doPreOperations(){
	myEcho 0 info T2 "Pre-operacoes..."
}


# ######################################################################
doPosOperations() {
	myEcho 0 info T2 "Pos-operacoes..."
	
	# remove cache in the instances
	#removeCache
	
	# ajusta permissoes do diretorio backup, para que seja possivel excluir a pasta backup ao final da desinstalacao
	myEcho 1 debug S  "chmod -R 755 backup"
	chmod -R 755 backup
	
	
	doSpecificOperations {ENGINE}      "upgradeVersion"	
}




# ######################################################################
# iniciador do processo de desinstalacao
main() {
	init
	
	myEcho 0 info T1 "Desinstalacao iniciada..."
	
	#convertFiles "backup"  |  listEchoInfo
	
	doPreOperations  &&  startUninstallSO  &&   doPosOperations  &&  endUninstallSO
	
	removeTmpFiles
	
	echo ""
	myEcho 0 info S "Desinstalacao finalizada"
}


main
return $?
