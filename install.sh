#!/bin/sh
# ######################################################################
#  PACKAGE INSTALLER - MAIN SCRIPT
# ######################################################################

# ARGUMENTS READER
GLO_SCRIPT_ARGUMENTS=$@
GLO_INSTALL_OPERATION=$(echo $1 | tr [:lower:] [:upper:])

# --- impede o script ser executado diretamente                             
if [ "$GLO_INSTALL_OPERATION" == "" ]; then                                                 
	echo "[ERROR] Operacao nao informada"
	echo "[INFO] Exemplo:"
	echo "[INFO] ./install.sh validate - realiza apenas a validacao"
	echo "[INFO] ./install.sh start    - inicia processo de instalacao"

	exit 1                                                           
fi 


# ######################################################################
# INITIALIZING, LOADING SCRIPTS, GLOBAL VARIABLES
init() {
	# this var is used at all this installation script
	export GLO_PACKAGE_DIR=`pwd`
	echo ""; echo ""; echo "";
	echo "[INFO] Preparando os arquivos..."	
	# lib
	dos2unix $GLO_PACKAGE_DIR/scripts/libs/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/libs/*.sh
	
	# prepare
	
	# --- libraries loading
	source $GLO_PACKAGE_DIR/scripts/libs/common_lib.sh
	source $GLO_PACKAGE_DIR/scripts/libs/core_lib.sh


	# ===== global variables declarations
	GLO_TIMESTAMP=`date +"%Y%m%d%H%M%S"`                                        
	GLO_HOSTS_INSTALLATION_DATABASE="host1 host2" 

	GLO_LOGFILE=$GLO_PACKAGE_DIR/logs/install_so_"$GLO_TIMESTAMP".log                    
	GLO_LOGFILE_DATABASE=$GLO_PACKAGE_DIR/logs/install_database_"$GLO_TIMESTAMP".log
	GLO_LOGFILE_BACKUP=$GLO_PACKAGE_DIR/logs/backup_"$GLO_TIMESTAMP".log  

	GLO_INSTALL_OPERATION_BACKUP="BACKUP"
	GLO_INSTALL_OPERATION_START="START"
	GLO_INSTALL_OPERATION_VALIDATE="VALIDATE"
		
	# other vars
	export NLS_LANG=PORTUGUESE_BRAZIL.WE8MSWIN1252   

	
	# ===== GLOBAL VARIABLES REQUIRED TO THE LIBRARIES
	#BACKUPDIR=$GLO_PACKAGE_DIR/backup
	GLO_BACKUPDIR=backup
	#UNINSTALL_FILE=$GLO_PACKAGE_DIR/backup/uninstall_list_files.txt
	GLO_UNINSTALL_FILE=backup/uninstall_list_files.txt
	GLO_TMPDIR=tmp

	GLO_SYSTEM_FILE=$SYSTEM_PATH/environment.cfg
	GLO_TRUE=0
	GLO_FALSE=1
	GLO_SUCCESS=0
	GLO_ERROR=1
	
	GLO_STATUSCMD=$GLO_SUCCESS

	GLO_NUM_GLO_STATUSCMDERROR=0   # error counting

	# === PRIMARY VALIDATIONS
	load_VarInstallerProperties
	isValid_Var_SystemFile	||  exit $GLO_ERROR
}



# ######################################################################
# PREPARES FILES BEFORE USING THEM (PERMISSIONS FILES, CONVERSIONS)
prepare() {
	echo ""
	echo "[INFO] Preparando os arquivos..."
	
	# lib
	dos2unix $GLO_PACKAGE_DIR/scripts/libs/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/libs/*.sh
	
	# SO
	dos2unix $GLO_PACKAGE_DIR/scripts/so/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/so/install_so_routines.sh
	
	# BANCO
	dos2unix $GLO_PACKAGE_DIR/scripts/database/install_database_routines.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/database/install_database_routines.sh
}


checkLogInstallation(){
	echo ""
	myEcho 0 info S "Por favor, verifique o log '$GLO_LOGFILE' para detalhes da instalacao de SO."	
	checkLog "$GLO_LOGFILE"
	
	echo ""	
	if [ -e "$GLO_LOGFILE_DATABASE" ]; then
		myEcho 0 info S "Por favor, verifique o log '$GLO_LOGFILE_DATABASE' para detalhes da instalacao do Banco de Dados."	
		checkLog "$GLO_LOGFILE_DATABASE"
	else
	  local HOST_VALIDATION1=`echo $GLO_HOSTS_INSTALLATION_DATABASE | grep $HOSTNAME`
      if [[ "$HOST_VALIDATION1" != "" ]]; then
		    myEcho 0 info S "Não houve instalacao no Banco de Dados a partir do host '$( getCurrentHostName)'."
      fi
	fi
	
}

installationSO(){
	local result=$GLO_SUCCESS
	myEcho 0 info T1 "Iniciando - S.O..."
	
	# trata os arquivos de instalacao
	echo "[INFO] Preparando os arquivos..."	
	dos2unix $GLO_PACKAGE_DIR/scripts/so/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/so/install_so_routines.sh
	
	# loga a saida (padrao e erro) em arquivo
	# obs: utilizando source as variaveis serao compartilhadas entre os scripts
	source $GLO_PACKAGE_DIR/scripts/so/install_so_routines.sh  $GLO_TIMESTAMP  2>&1  |  tee -a  "$GLO_LOGFILE"
	result=${PIPESTATUS[0]}    # quero somente o exit status do install_so_routines.sh
	
	#color()  (set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
	removeColorCodes "$GLO_LOGFILE"
	
	return $result
}

installationDatabase(){
	local result=$GLO_SUCCESS
	
	# trata os arquivos de instalacao
	echo "[INFO] Preparando os arquivos..."	
	dos2unix $GLO_PACKAGE_DIR/scripts/database/install_database_routines.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/database/install_database_routines.sh
	
	
	# loga a saida (padrao e erro) em arquivo
	source $GLO_PACKAGE_DIR/scripts/database/install_database_routines.sh  $GLO_TIMESTAMP  2>&1  |  tee -a $GLO_LOGFILE_DATABASE
	result=${PIPESTATUS[0]}    # quero somente o exit status do install_so_routines.sh
	removeColorCodes "$GLO_LOGFILE_DATABASE"
}

verifyHostInstallationDatabase(){
	# instala a parte de banco de dados		
	myEcho 0 info T1 "Iniciando - Banco de Dados..."

	# valida se o host e um host permitido para a instalacao da parte de banco de dados
	local HOSTNAME=`hostname -s`
	local HOST_VALIDATION=`echo $GLO_HOSTS_INSTALLATION_DATABASE | grep $HOSTNAME`
	
	local INSTALLATION_DATABASE_MADE="database"
	local INSTALLATION_DATABASE_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $INSTALLATION_DATABASE_MADE`
	
	# valida se ja foi realizada alguma instalacao do banco. Se foi, aborta a instalacao no banco.
	if [[ "$INSTALLATION_DATABASE_VALIDATION" == "" ]];then
	
		if [[ "$HOST_VALIDATION" != "" ]]; then
			sed -i "$ a $INSTALLATION_DATABASE_MADE" $GLO_PACKAGE_DIR/control
			installationDatabase
		fi
		
	else
		echo ""
		myEcho 0 warn S "A instalacao no banco sera abortada, pois a mesma ja foi realizada."
		exit 0
	fi
}

checkLogBackup(){
	echo ""
	myEcho 0 info S "Por favor, verifique o log '$GLO_LOGFILE_BACKUP' para detalhes da realizacao do backup."
	checkLog $GLO_LOGFILE_BACKUP
}

createBackup(){
	# trata os arquivos de instalacao
	echo "[INFO] Preparando os arquivos..."	
	dos2unix $GLO_PACKAGE_DIR/scripts/backup/*.sh
	chmod 755 $GLO_PACKAGE_DIR/scripts/backup/backup_routines.sh

	
	# loga a saida (padrao e erro) em arquivo
	source $GLO_PACKAGE_DIR/scripts/backup/backup_routines.sh $GLO_TIMESTAMP 2>&1 | tee -a $GLO_LOGFILE_BACKUP
}


controlInstallation() {
	# controla o processo de instalacao
	local FIRST_INSTALLATION="firstInstallation"
	local INSTALLATION_MADE="installation"
	local FIRST_INSTALLATION_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $FIRST_INSTALLATION | wc -l`
	local INSTALLATION_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $INSTALLATION_MADE | wc -l`
	local UNINSTALLATION_MADE="remotion"
	local TRUE=1
	
	if [ ! $INSTALLATION_VALIDATION == $TRUE ];then
	
		if [ ! $FIRST_INSTALLATION_VALIDATION == $TRUE ];then
			sed -i "$ a $FIRST_INSTALLATION" $GLO_PACKAGE_DIR/control
		fi
		
		sed -i "$ a $INSTALLATION_MADE" $GLO_PACKAGE_DIR/control
		sed -i "/$UNINSTALLATION_MADE/d" $GLO_PACKAGE_DIR/control
	else
		echo ""
		myEcho 0 warn S "A instalacao sera abortada, pois a mesma ja foi realizada"
		exit 1
	fi
}

controlBackup() {
	local BACKUP_MADE="backup"
	local BACKUP_VALIDATION=`cat $GLO_PACKAGE_DIR/control | grep $BACKUP_MADE | wc -l`
	local TRUE=1

	if [ ! $BACKUP_VALIDATION == $TRUE ];then
		sed -i "$ a $BACKUP_MADE" $GLO_PACKAGE_DIR/control
	else
		echo ""
		myEcho 0 warn S "O backup sera abortado, pois o mesmo ja foi realizado"
		
		exit 1
	fi
}


# ######################################################################
# ROTINA PRINCIPAL
main() {	
	init
	if [[ ($GLO_INSTALL_OPERATION == $GLO_INSTALL_OPERATION_VALIDATE) ]]; then 
	
		# instala a parte de SO
		myEcho 0 info T1 "Iniciando - S.O..."
		installationSO

		echo ""
		# verifica o log da instalacao
		checkLogInstallation
	
	elif [[ ($GLO_INSTALL_OPERATION == $GLO_INSTALL_OPERATION_START) ]]; then 
	
		# controla a instalacao
		# controlInstallation
		
		installationSO  &&  verifyHostInstallationDatabase
		
		echo ""
		# verifica o log da instalacao
		checkLogInstallation
		
	elif [[ $GLO_INSTALL_OPERATION == $GLO_INSTALL_OPERATION_BACKUP ]]; then
		# controla o backup
		# controlBackup
	
		# instala a parte de SO
		myEcho 0 info T1 "Iniciando - Backup Produto..."
		createBackup
		
		echo ""
		# verifica o log da instalacao
		checkLogBackup
	
	else
		echo ""
		myEcho 0 error S "Operacao invalida"
	fi
}


main