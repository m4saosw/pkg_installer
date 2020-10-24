#!/bin/sh
#############################################################################
# INSTALLER PACKAGE
# SCRIPT DE INSTALACAO S.O
#############################################################################


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
	createBackupDir
	# createUninstallFile
}		


# ######################################################################
doPreOperations(){
	myEcho 0 info T2 "Pre-operacoes..."
	local result=$GLO_SUCCESS
	
	# insira aqui pre-operacoes
	removeTmpFiles
	
	return $result
}

# ######################################################################
doPosOperations() {
	myEcho 0 info T2 "Pos-operacoes..."
	local result=$GLO_SUCCESS

	# remove cache in the instances
	#removeCache
	
	doSpecificOperations {ENGINE}      "upgradeVersion"
	
	return $result
}


# ######################################################################
# redefine o password do arquivos
modifyPassword(){
	local arq="$1"
	local stringKey="{INPUT_PASSWORD}"
	# ====== INTEGRATION PASSWORD
	local DBIT_PASSWORD_ACM_SOL=`cat /opt/ptin/acm/system/environment.cfg | grep "db.integration.password.acm_sol=" | awk -F "=" {'print $2'}`   

	echo ""	
	
	myEcho 1 info S "Inserindo password... $arq..."
		
	sed -i "s/$stringKey/$DBIT_PASSWORD_ACM_SOL/g" "$arq"
}


# ######################################################################
# altera conteudo de arquivos
modifyCfgFiles(){
	echo ""
	myEcho 0 info S "Alterando definicoes de arquivos..."
	
}


# ######################################################################
# obtem o EngineId do Host
modifyCfgEngineIdHost(){
	local attr_id="$1"
	local file_basename="$2"
	echo ""
		
	for instance_folder in ` grep "engine.inst.*.path" $GLO_SYSTEM_FILE | awk -F "=" {'print $2'}`; do
		
		local num_instance=`basename "$instance_folder"`
		
		local arq="$instance_folder/$file_basename"
		
		myEcho 1 info S "Alterando... $arq... $num_instance"
		
		sed -i "s/$attr_id=.*/$attr_id=$num_instance/g" "$arq"
	done;

}


# ######################################################################
# obtem o EngineId da Aplicacao
modifyCfgEngineIdApplication(){
	local attr_id="$1"
	local file_basename="$2"
	echo ""	
	
	for instance_folder in ` grep "engine.inst.*.path" $GLO_SYSTEM_FILE | awk -F "=" {'print $2'}`; do
		
		local num_instance=`grep "^engine.id=" $instance_folder/configuration/ams.properties | awk -F "=" {'print $2'}`
		
		local arq="$instance_folder/$file_basename"
	
		myEcho 1 info S "Alterando... $arq... $num_instance"
		
		sed -i "s/$attr_id=.*/$attr_id=$num_instance/g" "$arq"
	done;

}

# ######################################################################
doInstall() {
	#load_InstallerProperties
	local result=$GLO_SUCCESS
	
	local statusValidacao=-1
	local statusBackup=-1
	local statusInstall=-1
	
	# --- loop infinito
	while : ; do
		#generatePreprocessingFile   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break"; }
		#GLO_STATUSCMD=$?
		#myEcho 0 debug S "GLO_STATUSCMD generatePreprocessingFile=$GLO_STATUSCMD"		
		
		
		etapa1PreValidacao   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; statusValidacao=$GLO_ERROR; exitStatusHandler "break"; }
		statusValidacao=$GLO_SUCCESS
		#GLO_STATUSCMD=$?			
		#myEcho 0 debug S "GLO_STATUSCMD etapa1PreValidacao=$GLO_STATUSCMD"
		#exitOnStatusCmdError
		#NUM_GLO_STATUSCMDERROR=0		
		
		
		if [[ ($GLO_INSTALL_OPERATION != $GLO_INSTALL_OPERATION_VALIDATE) ]]; then 
			
			etapa2Backup   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; statusBackup=$GLO_ERROR; exitStatusHandler "break"; }
			statusBackup=$GLO_SUCCESS
			#GLO_STATUSCMD=$?			
			#myEcho 0 debug S "GLO_STATUSCMD etapa2Backup=$GLO_STATUSCMD"
			#||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }	
			#exitOnStatusCmdError
			   
			
			etapa3Install   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; statusInstall=$GLO_ERROR; exitStatusHandler "break"; }
			statusInstall=$GLO_SUCCESS
			#GLO_STATUSCMD=$?			
			#myEcho 0 debug S "GLO_STATUSCMD etapa3Install=$GLO_STATUSCMD"
			#exitOnStatusCmdError
			
			# etapa4ValidacaoPos	
			#GLO_STATUSCMD=$?
			#myEcho 0 debug S "GLO_STATUSCMD=$GLO_STATUSCMD"
		fi		
		
		break
	done
	
	myEcho 0 info B1 "$( getStatusEtapasInstall  $statusValidacao  $statusBackup  $statusInstall )"
	
	# --- se diretorio de backup esta vazio, exclui
	if [[ ! "$(ls -A $GLO_BACKUPDIR)" ]]; then
		echo ""
     	myEcho 0 info S "Excluindo diretorio de Backup vazio ($GLO_BACKUPDIR)"
		rm -rf "$GLO_BACKUPDIR"
	fi
	
	return $result
}


# ######################################################################
getStatusEtapasInstall() {
	local statusValidacao=$1
	local statusBackup=$2
	local statusInstall=$3
	
	echo "Status das Etapas Executadas - S.O."
	echo ""
	echo -e "Validacao............" $( showStatusEtapa $statusValidacao )
	echo -e "Backup..............." $( showStatusEtapa $statusBackup )
	echo -e "Instalacao..........." $( showStatusEtapa $statusInstall )
}


# ######################################################################
showStatusEtapa() {
	local status=$1
	
	case  $status  in
		-1)
			echo "Nao efetuado"
			;;
		0)
			myEchoColor "GREEN" "OK"
			#echo "OK"
			;;
		*)
			myEchoColor "RED" "ERRO"
			#echo "ERRO"
			;;
	esac 
}


# ######################################################################
# ROTINA PRINCIPAL
main() {
	local result=$GLO_SUCCESS
	
	init
	
	myEcho 0 info T1 "Instalacao SO iniciada..."

	if [[ ($GLO_INSTALL_OPERATION == $GLO_INSTALL_OPERATION_VALIDATE) ]]; then 
		convertFiles "files"  &&  allowFiles "files"  &&  doInstall  ||   result=$GLO_ERROR
	else 
		convertFiles "files"  &&  allowFiles "files"  &&  doPreOperations  &&  doInstall  &&  doPosOperations    ||   result=$GLO_ERROR
	fi
	
	removeTmpFiles
	echo ""
	myEcho 0 info S "Instalacao SO finalizada"
	
	return $result
}


main
return $?
