#!/bin/sh
#############################################################################
# INSTALLER PACKAGE
# COMMONS LIBRARY
#############################################################################
# A lib utiliza as seguintes variaveis que devem ser inicializadas pelo script chamador:
#	GLO_SYSTEM_FILE 
#	GLO_GLO_BACKUPDIR
#	GLO_GLO_UNINSTALL_FILE
#	GLO_TIMESTAMP
#   GLO_NUM_GLO_STATUSCMDERROR
#   GLO_STATUSCMD
#############################################################################


# ######################################################################
# ANALISA O EXIT STATUS DO ULTIMO COMANDO E, EM CASO DE STATUS DE ERRO ACIONA O COMANDO DE QUEBRA DE FLUXO DESEJADO
# $1 - etapa
# $2 - acao de quebra de fluxo - (break, continue, exit)
exitStatusHandler() {
	local statement="$1"
	
	# ****** se foram encontrados erros
	if [ $GLO_STATUSCMD -ne 0 ]; then
		
		GLO_NUM_GLO_STATUSCMDERROR=`expr $GLO_NUM_GLO_STATUSCMDERROR + 1`
		myEcho 0 error S "Ocorreu um Erro durante a execucao do Comando ou Processo anterior. Foi tomada a acao do tipo: $statement"
		eval "$statement"
	else
		myEcho 0 debug S "OK"
	fi
}


# ######################################################################
# TODO - ESTA FUNCAO AINDA NAO ESTA SENDO USADA
# Analisa o exit status do ultimo comando e toma uma acao pre-definida
# $1 - etapa
# $2 - acao de quebra de fluxo - (break, continue, exit)
exitStatusHandler2() {
	local etapa="$1"
	local statementOnContinue="$2"
	local statementOnBreak="$3"
	
	if [ "$statementOnContinue" == "-" ]; then
		statementOnContinue="continue"
	fi
	
	if [ "$statementOnBreak" == "-" ]; then
		statementOnBreak="break"
	fi
	
	
	# ****** se foram encontrados erros
	if [ $GLO_STATUSCMD -ne 0 ]; then
		if [ "$etapa" == "backup" ]; then
			
			if [ "$GLO_PROCESS_BACKUP_CONTINUEONERROR" == "S" ]; then
				GLO_NUM_GLO_STATUSCMDERROR=`expr $GLO_NUM_GLO_STATUSCMDERROR + 1`
				myEcho 0 error S "Ocorreu um erro. O processo prosseguira."
				eval "$statementOnContinue"
			else
				myEcho 0 error S "Ocorreu um erro. Processo interrompido."
				eval "$statementOnBreak"
			fi
			
		elif [ "$etapa" == "install" ]; then
			
			if [ "$GLO_PROCESS_INSTALL_CONTINUEONERROR" == "S" ]; then
				GLO_NUM_GLO_STATUSCMDERROR=`expr $GLO_NUM_GLO_STATUSCMDERROR + 1`
				myEcho 0 error S "Ocorreu um erro. O processo prosseguira."
				eval "$statementOnContinue"
			else
				myEcho 0 error S "Ocorreu um erro. Processo interrompido."
				eval "$statementOnBreak"
			fi
		else
			GLO_NUM_GLO_STATUSCMDERROR=`expr $GLO_NUM_GLO_STATUSCMDERROR + 1`
			myEcho 0 error S "Ocorreu um erro. Acao tomada:  $statementOnContinue"
			eval "$statementOnContinue"
		fi
	fi
}


# ######################################################################
# TODO - ESTA FUNCAO AINDA NAO ESTA SENDO USADA
# Se foi encontrado algum erro no processo exibe uma mensagem de usuario e sai da execucao
# $1 - mensagem
exitOnFoundStatusCmdError() {
	# ****** se foram encontrados erros
	if [ $GLO_NUM_GLO_STATUSCMDERROR -gt 0 ]; then
		myEcho 0 warn S "Devido a erros ocorridos o processo sera abortado. $1"
		myEcho 0 info S "Processo abortado"

		exit 1
	fi
}



# ######################################################################
# TODO - ESTA FUNCAO AINDA NAO ESTA SENDO USADA
# Exibe uma mensagem de erro generica e termina execucao com exit
exitOnStatusCmdError() {
	# ****** se ocorreu erro no comand
	if [[ $GLO_STATUSCMD -ne 0 ]]; then
		myEcho 0 error S "Ocorreu um erro na operacao anterior. Processo abortado"

		exit 1
	fi
}



# ######################################################################
# TODO - ESTA FUNCAO AINDA NAO ESTA SENDO USADA
# Exibe uma mensagem de erro generica e continua execucao
continueOnStatusCmdError() {
	# ****** se ocorreu erro no comand
	if [[ $GLO_STATUSCMD -ne 0 ]]; then
		myEcho 0 error S "Ocorreu um erro na operacao anterior. Processo abortado"

		GLO_NUM_GLO_STATUSCMDERROR=`expr $GLO_NUM_GLO_STATUSCMDERROR + 1`

		return 1
	fi
}






# ######################################################################
isValid_Var_SystemFile() {
	# ***** valida variavel de ambiente
	if [ ! -f "$GLO_SYSTEM_FILE" ]; then
		myEcho 0 error S "Arquivo de configuracao de ambiente '$GLO_SYSTEM_FILE' nao encontrado."
		myEcho 0 info S "Verifique se a variavel 'SYSTEM_PATH' esta definida e esta executando com usuario correto."
		myEcho 0 info S "Processo abortado"

		return $GLO_ERROR
	fi
}



# ######################################################################
# EXIBE INFORMACOES UTEIS DO AMBIENTE - COMO CABECALHO DA DES/INSTALACAO - USO PRIVADO DAS ROTINAS INTERNAS
headerInfo() {
	echo ""
	myEcho 0 info S "#####################################################################"
	myEcho 0 info S "PACKAGE INSTALLER  2.0.0.4 beta"
	myEcho 0 info S " "
	myEcho 0 info S "Script Executado: `echo $0  $GLO_SCRIPT_ARGUMENTS`"     # – Exibe o nome do programa ou script executando
	myEcho 0 info S "Diretorio:        `pwd`"	
	myEcho 0 info S "Host:             `hostname -s`"
	myEcho 0 info S "User:             `whoami`"
	myEcho 0 info S "PID:              `echo $$`"
	myEcho 0 info S "Hora:             `date +"%d-%m-%Y %H:%M:%S"`"
	echo ""
}




# ######################################################################
# CRIA O DIRETORIO DE BACKUP
createBackupDir() {
	if [ -d "$GLO_BACKUPDIR" ]; then
		myEcho 0 error S "Ja existe uma instalacao efetuada anteriormente. Por favor desinstale para poder instalar novamente (para instalar forcadamente renomeie o diretorio '$GLO_BACKUPDIR' para outro nome)"
		myEcho 0 info S "Instalacao abortada"
		exit 1
	else
		myEcho 0 info S "Criando diretorio de backup '$GLO_BACKUPDIR'"
		mkdir $GLO_BACKUPDIR 
	fi
}



# ######################################################################
# VERIFICA EXISTENCIA DO DIRETORIO DE BACKUP
checkBackupDir() {
	if [ ! -d "$GLO_BACKUPDIR" ]; then
		myEcho 0 error S "Nao e possivel desinstalar pois nao ha uma instalacao anterior ou o diretorio do backup '$GLO_BACKUPDIR' foi deletado."
		myEcho 0 info S "Desinstalacao abortada"

		exit 1
	fi
}




# ######################################################################
# CRIA O ARQUIVO AUXILIAR DE DESINSTALACAO
createUninstallFile() {
	if [ -f "$GLO_UNINSTALL_FILE" ]; then
		myEcho 0 info S "Removendo arquivo auxiliar pre-existente '$GLO_UNINSTALL_FILE'"
		rm -f "$GLO_UNINSTALL_FILE"
	fi
	myEcho 0 info S "Criando arquivo auxiliar '$GLO_UNINSTALL_FILE'"

	touch "$GLO_UNINSTALL_FILE"
	echo "# Lista de arquivos para o script de desinstalacao - nao remova este arquivo" >> "$GLO_UNINSTALL_FILE"
	echo "# Origem refere-se ao arquivo backup. Destino refere-se ao local para onde deve ser restaurado"  >> "$GLO_UNINSTALL_FILE"
}



# ######################################################################
# FINALIZA O PROCESSO DA DESINSTALACAO
endUninstallSO() {
	echo ""
	#remove backup files generated by installation process (to permit a new installation in the future)
	myEcho 0 info S "Removendo pasta de backup '$GLO_BACKUPDIR'"
	rm -rf $GLO_BACKUPDIR

	myEcho 0 info S "Removendo arquivo auxiliar de desinstalacao '$GLO_UNINSTALL_FILE'"
	rm -rf   $GLO_UNINSTALL_FILE
}




# ######################################################################
# ANALISA O ARQUIVO DE LOG PROCURANDO POR POSSIVEIS ERROS
# $1 - arquivo de log
checkLog() {
	#desabilitado - procura por strings que nao sejam do padrao
	#PATTERN="\[info\]|\[debug\]|dos2unix"
	#NUM=`cat "$1"  | sed '/^$/d'  |  grep -vEc $PATTERN`

	#procura por strings sejam do padrao
	PATTERN="\[error\]|ORA-"
	NUM=`cat "$1"  |  grep -iEc "$PATTERN"`
	if [ "$NUM" != "0" ]; then
		myEcho 0 warn S "Ocorreram $NUM mensagens de erros, pelo menos."

		return 1
	fi
}



# ######################################################################
# remove cache in the instances
removeCache(){
	echo ""
	myEcho 0 info S "Removendo cache da instancias..."
	
	for instance_folder in ` grep "engine.inst.*.path" $GLO_SYSTEM_FILE | awk -F "=" {'print $2'}`; do
		myEcho 1 info S "Removendo cache da instancia "${instance_folder:30:30}"..."
		rm -rf $instance_folder/cache/
	done;
}


# ######################################################################
# upgrade solution configs
upgradeVersion(){
    echo ""
	myEcho 1 info S "Atualizando as configuracoes da solucao (upgrade_version.sh)..."
	echo ""
	local ACM_SCRIPTS_PATH=` grep "acm.scripts.path" $GLO_SYSTEM_FILE | awk -F "=" {'print $2'}`	
	$ACM_SCRIPTS_PATH/upgrade_version.sh
}







# ######################################################################
# RETORNA TRUE CASO O HOST INFORMADO SEJA O HOST CORRENTE
# modo de uso1: if isCurrentHost "1tokyo" ; then
# modo de uso2: if isCurrentHost "1tokyo" || isCurrentHost "1tokyo" ; then
isCurrentHost() {
	local _TRUE=1
	local HOSTFOUND=`hostname | grep $1 | wc -l`

	# ***** sai da funcao caso a maquina atual seja diferente do esperado
	if [ $HOSTFOUND != $_TRUE ]; then
		return 1
	fi
}






# ######################################################################
# REMOVE QUALQUER CODIGO DE CORES
removeColorCodes() {
	sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g"  "$1"
}


# ######################################################################
# OBTEM UM TIMESTAMP  (MILISEGUNDOS)
getTimestamp() {
	date +%s%N  |  cut -b1-13
}



# ######################################################################
# LE A ENTRADA E DEVOLVE A SAIDA COM ECHOS DO TIPO ERROR
listEchoError() {
	local msg="$1"
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		myEcho 0 error S "$msg  $line"
	done
}


# ######################################################################
# LE A ENTRADA E DEVOLVE A SAIDA COM ECHOS DO TIPO INFO
listEchoInfo() {
	local list="$(</dev/stdin)"

	local msg="$1"
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		myEcho 0 info S "$msg  $line"
	done <<< "$list"
}


# ######################################################################
# ELIMINA LINHAS DE COMENTARIOS DA STDIN, E LINHAS EM BRANCO. O RESULTADO SAI NA STDOUT
# Os seguintes casos sao cobertos:
# emulate.root_path=my root path certo   # certo com comentario    - NãO apaga esta linha   (cuidado: evite comentarios ao final da linha)
#          # emulate.root_path=sujeira espaco                      - ok
#	# emulate.root_path=sujeira tab                                - ok
# #emulate.root_path=sujeira                                       - ok
cleanComments() {
	# entrada - de dois modos:  via stdin  ou  parametro1
	
	local file="$1"
	
	if [ "$file" == "" ]; then
		# opcao nao recomendada, baixa performance
		local line   # importante usar para nao misturar dados com algum outro processo concorrente
		while read line; do
			echo "$line"  |  grep -Ev  "^[[:blank:]]*#"  |  grep -v ^$
		done
	else
		# melhor opcao, alta performance
		grep -Ev  "^[[:blank:]]*#"  "$file"  |  grep -v ^$
	fi
}


# ######################################################################
# LIMPA PATHS COM BARRAS DUPLICADAS
cleanPath() {
	local patternRemoveDoubleSlash="s#//#/#g"
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		echo $line  |  sed "$patternRemoveDoubleSlash"
	done
}



# ######################################################################
# RETORNA UM ARQUIVO TEMPORARIO
# $1 - prefixo desejado (opcional)
# retorno: imprime o path do arquivo na stdout
# exit status: erro caso nao consiga criar arquivo
getTmpFilename() {
	local prefix="$1"
	local tmpFile="$GLO_TMPDIR/tmp_file_$(getTimestamp)_$prefix.tmp"

	# ATENCAO: nao imprimir mensagens na saida padrao. A funcao chamadora (que usa pipe) espera receber somente um print com o nome do arquivo temporario gerado
	myEcho 0 debug S "Criando arquivo temporario... $tmpFile"  >&2
	
	if [ -f "$tmpFile" ]; then
		myEcho 0 error S "[getTmpFilename] Arquivo temporario $tmpFile ja existe!"  >&2
		return 1
	fi

	local dir=$(dirname "$tmpFile")
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	touch "$tmpFile"
	echo "$tmpFile"
}



# ######################################################################
# FAZ UM ECHO PERSONALIZADO  (INDENTACAO, NIVEL DE LOG E COLORIDO)
# se for utilizar em conjunto com o tee, utilize ao final o removeColorCodes
# $1 - nivel (0 a n)
# $2 - tipo (info debug error warn)
# $3 - tipo de texto (S - simples,  T1 - titulo1,  T2 - titulo2,  P1 - paragrafo,  B1 - box1)
# $4 - a mensagem
myEcho() {
	# atencao: necessita da variavel showDebugMessages definida

	local  CONT=0
	local  S=""
	local  TABSPACE="    "
	
	# --- codigo de cores
	local  GRAY='\e[1;30m'
	local  RED='\e[0;31m'
	local  YELLOW='\e[0;33m'
	local  BLUE='\e[1;34m'
	local  GREEN='\e[0;32m'	
	local  CYAN='\e[0;36m'	
	local  NOCOLOR='\e[0m'
	
	local  COLOR=$NOCOLOR
	local  LEVEL=$( echo $2     |  tr '[a-z]' '[A-Z]' )
	local  textType=$( echo $3  |  tr '[a-z]' '[A-Z]' )
	local  message=$4
	local  timeNow=$( date +"%T" )	
	local  strLevel="[$LEVEL][$timeNow] "
	
		
	# mensagem vazia, sai
	if [ "$message" == "" ]; then
		return 0
	fi
	
	if [ "$message" == " " ]; then
		if [[ ("$LEVEL" == "DEBUG" && $GLO_SHOW_DEBUG_MESSAGES == "S") || ("$LEVEL" != "DEBUG")  ]]; then
			echo ""
			return 0
		fi
	fi
	

	if [ "$LEVEL" == 'ERROR' ]; then
		COLOR=$RED
	elif [ "$LEVEL" == 'WARN' ]; then
		COLOR=$YELLOW
	elif [ "$LEVEL" == 'DEBUG' ]; then
		#COLOR=$BLUE
		COLOR=$GRAY
	elif [ "$LEVEL" == 'INFO' ]; then
		COLOR=$NOCOLOR
		#COLOR=$GREEN
	elif [ "$LEVEL" == 'NONE' ]; then
		strLevel=""
	fi

	while [ $CONT -lt $1 ]; do
		S+="$TABSPACE"
		CONT=$( expr $CONT + 1 )
	done

	# validacao caso mensagem seja level debug, precisa estar com show debug ativado
	if [[ ("$LEVEL" == "DEBUG" && $GLO_SHOW_DEBUG_MESSAGES == "S") || ("$LEVEL" != "DEBUG")  ]]; then

		# --- tratamento do tipo de texto (pre-texto)
		case  $textType  in
			"T1")
				echo ""
				echo ""
				echo ""
				echo ""
				echo -e "$S$CYAN$strLevel####################################################################################################$NOCOLOR"
				;;
			"T2")
				echo ""
				echo ""
				echo -e "$S$CYAN$strLevel*************************************************************************************$NOCOLOR"
				;;
			"B1")
				echo ""
				echo ""
				echo -e "$S$CYAN$strLevel=========================================================================$NOCOLOR"
				;;
			"P1")
				echo ""
				;;            
			*)
		esac 
	
		# echo colorido ou sem cor
		if [[ $GLO_SHOW_COLOR_MESSAGES == "S" ]]; then
			# itera pela lista, caso seja uma lista
			local line
			while read line; do
				echo -e "$S$COLOR$strLevel$line$NOCOLOR"
			done <<< "$message"
		else
			# itera pela lista, caso seja uma lista
			local line
			while read line; do
				echo "$S$strLevel$line"
			done <<< "$message"
		fi
		
		
		# --- tratamento do tipo de texto (pos-texto)
		case  $textType  in
			"T1"|"T2")
				echo ""
				;;
			"B1")
				echo -e "$S$CYAN$strLevel=========================================================================$NOCOLOR"
				echo ""
				echo ""
				;;
			*)
		esac 
	fi
}

# ######################################################################
# ESTA FUNCAO NAO ESTA SENDO USADA. ESTA EM DESENVOLVIMENTO - Tentando INTEGRAR com a funcao myEchoColor
# FAZ UM ECHO PERSONALIZADO  (INDENTACAO, NIVEL DE LOG E COLORIDO)
# se for utilizar em conjunto com o tee, utilize ao final o removeColorCodes
# $1 - nivel (0 a n)
# $2 - tipo (info debug error warn)
# $3 - tipo de texto (S - simples,  T1 - titulo1,  T2 - titulo2,  P1 - paragrafo,  B1 - box1)
# $4 - a mensagem
myEcho_() {
	# atencao: necessita da variavel showDebugMessages definida
	local  CONT=0
	local  S=""
	local  TABSPACE="    "
	
	local  COLOR
	local  LEVEL=$( echo $2     |  tr '[a-z]' '[A-Z]' )
	local  textType=$( echo $3  |  tr '[a-z]' '[A-Z]' )
	local  message=$4
	local  timeNow=$( date +"%T" )	
	local  strLevel="[$LEVEL][$timeNow] "
	
		
	# mensagem vazia, sai
	if [ "$message" == "" ]; then
		return 0
	fi
	
	if [ "$message" == " " ]; then
		if [[ ("$LEVEL" == "DEBUG" && $GLO_SHOW_DEBUG_MESSAGES == "S") || ("$LEVEL" != "DEBUG")  ]]; then
			echo ""
			return 0
		fi
	fi
	

	if [ "$LEVEL" == 'ERROR' ]; then
		COLOR=RED
	elif [ "$LEVEL" == 'WARN' ]; then
		COLOR=YELLOW
	elif [ "$LEVEL" == 'DEBUG' ]; then
		#COLOR=BLUE
		COLOR=GRAY
	elif [ "$LEVEL" == 'INFO' ]; then
		COLOR=NOCOLOR
		#COLOR=$GREEN
	elif [ "$LEVEL" == 'NONE' ]; then
		strLevel=""
	fi

	while [ $CONT -lt $1 ]; do
		S+="$TABSPACE"
		CONT=$( expr $CONT + 1 )
	done

	# validacao caso mensagem seja level debug, precisa estar com show debug ativado
	if [[ ("$LEVEL" == "DEBUG" && $GLO_SHOW_DEBUG_MESSAGES == "S") || ("$LEVEL" != "DEBUG")  ]]; then

		# --- tratamento do tipo de texto (pre-texto)
		case  $textType  in
			"T1")
				echo ""
				echo ""
				echo ""
				echo ""
				myEchoColor "CYAN"  "$S$strLevel####################################################################################################"
				;;
			"T2")
				echo ""
				echo ""
				myEchoColor "CYAN" "$S$strLevel*************************************************************************************"
				;;
			"B1")
				echo ""
				echo ""
				myEchoColor "CYAN"  "$S$strLevel========================================================================="
				;;
			"P1")
				echo ""
				;;            
			*)
		esac 
	
		# echo colorido ou sem cor
		if [[ $GLO_SHOW_COLOR_MESSAGES == "S" ]]; then
			# itera pela lista, caso seja uma lista			
			local line
			while read line; do
				local mymsg=$( echo "$S$strLevel$line" )
				myEchoColor "$COLOR"  "$mymsg"
			done <<< "$message"
		else
			# itera pela lista, caso seja uma lista
			local line
			while read line; do
				echo "$S$strLevel$line"
			done <<< "$message"
		fi
		
		
		# --- tratamento do tipo de texto (pos-texto)
		case  $textType  in
			"T1"|"T2")
				echo ""
				;;
			"B1")
				myEchoColor "CYAN"  "$S$strLevel========================================================================="
				echo ""
				echo ""
				;;
			*)
		esac 
	fi
}


# ######################################################################
# FAZ UM ECHO COLORIDO
# $1 - cor (RED, YELLOW, BLUE, GREEN, CYAN, NOCOLOR)
# $2 - mensagem  (pode ser single ou multi-line)
myEchoColor() {
	local color=$( echo $1 |  tr '[a-z]' '[A-Z]' )
	local listMessage="$2"
	
	[[ "$listMessage" != "" ]]   ||  return 0
	
	# --- codigo de cores
	local  GRAY='\e[1;30m'
	local  RED='\e[0;31m'
	local  YELLOW='\e[0;33m'
	local  BLUE='\e[1;34m'
	local  GREEN='\e[0;32m'	
	local  CYAN='\e[0;36m'	
	local  NOCOLOR='\e[0m'
	local colorSelected
	
	eval colorSelected="$"$color

	if [[ $GLO_SHOW_COLOR_MESSAGES == "S" ]]; then
		local line
		while read line; do
			echo -e "$colorSelected$line$NOCOLOR"
		done <<< "$listMessage"
	else
		local line
		while read line; do
			echo "$line"
		done <<< "$listMessage"
	fi
}



# ######################################################################
convertFiles() {
	local dir="$1"

	echo ""
	myEcho 0 info N "Convertendo arquivos (dos2unix) do diretorio '$dir'..."

	find $dir -name '*.sh'  		-type f  -exec  dos2unix  -k {} \;
	find $dir -name '*.txt'  		-type f  -exec  dos2unix  -k {} \;
	find $dir -name '*.sql'  		-type f  -exec  dos2unix  -k {} \;
	find $dir -name '*.properties'  -type f  -exec  dos2unix  -k {} \;
	find $dir -name '*.xml'  		-type f  -exec  dos2unix  -k {} \;
	find $dir -name '*.cfg'  		-type f  -exec  dos2unix  -k {} \;
}

# ######################################################################
allowFiles() {
	local dir="$1"
	
	echo ""
	myEcho 0 info N "Concendendo provilegios de execucao (chmod +x) a arquivos sh do diretorio '$dir'..."
	
	find $dir -name '*.sh'  		-type f  -exec  chmod  +x {} \;
}


# ######################################################################
doSpecificOperations() {	

	ENGINE="prod1 prod2 local1"
	ENGINE_CLI=""
	ENGINE_PRD=""
	ENGINE_LOCAL=""
	ENGINE_RC=""
	INTEGRATION=""
	INTEGRATION_CLI=""
	INTEGRATION_PRD=""
	INTEGRATION_LOCAL=""
	INTEGRATION_RC=""
	APRESENTATION=""
	APRESENTATION_CLI=""
	APRESENTATION_PRD=""	
	APRESENTATION_LOCAL=""
	APRESENTATION_RC=""
	PRD=""
	HML=""
	LOCAL=""
	DEV=""
	RC=""
	
	HOST_INFORMED="$1"
	OPERATION=$2
	HOSTNAME=`hostname -s`
	TRUE=1
	
	if [ "$HOST_INFORMED" == "{ALL}" ]; then
		echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
		eval $OPERATION	
	elif [ "$HOST_INFORMED" == "{ENGINE}" ]; then
		HOST_VALIDATION=`echo $ENGINE | grep $HOSTNAME | wc -l`
		
		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION	
			return 0
		fi	
	elif [ "$HOST_INFORMED" == "{ENGINE_CLI}" ]; then
		HOST_VALIDATION=`echo $ENGINE_CLI | grep $HOSTNAME | wc -l`
		
		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{ENGINE_PRD}" ]; then
		HOST_VALIDATION=`echo $ENGINE_PRD | grep $HOSTNAME | wc -l`
		
		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi	
	elif [ "$HOST_INFORMED" == "{ENGINE_LOCAL}" ]; then
		HOST_VALIDATION=`echo $ENGINE_LOCAL | grep $HOSTNAME | wc -l`
		
		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{ENGINE_RC}" ]; then
		HOST_VALIDATION=`echo $ENGINE_RC | grep $HOSTNAME | wc -l`
		
		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	
	elif [ "$HOST_INFORMED" == "{INTEGRATION}" ]; then
		HOST_VALIDATION=`echo $INTEGRATION | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{INTEGRATION_CLI}" ]; then
		
		HOST_VALIDATION=`echo $INTEGRATION_CLI | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{INTEGRATION_PRD}" ]; then
		HOST_VALIDATION=`echo $INTEGRATION_PRD | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{INTEGRATION_LOCAL}" ]; then
		HOST_VALIDATION=`echo $INTEGRATION_LOCAL | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{INTEGRATION_RC}" ]; then
		HOST_VALIDATION=`echo $INTEGRATION_RC | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{APRESENTATION}" ]; then
		HOST_VALIDATION=`echo $APRESENTATION | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{APRESENTATION_CLI}" ]; then
		HOST_VALIDATION=`echo $APRESENTATION_CLI | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{APRESENTATION_PRD}" ]; then
		HOST_VALIDATION=`echo $APRESENTATION_PRD | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{APRESENTATION_LOCAL}" ]; then
		HOST_VALIDATION=`echo $APRESENTATION_LOCAL | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{APRESENTATION_RC}" ]; then
		HOST_VALIDATION=`echo $APRESENTATION_RC | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{PRD}" ]; then
		HOST_VALIDATION=`echo $PRD | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{HML}" ]; then
		HOST_VALIDATION=`echo $HML | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{LOCAL}" ]; then
		HOST_VALIDATION=`echo $LOCAL | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{RC}" ]; then
		HOST_VALIDATION=`echo $RC | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ "$HOST_INFORMED" == "{DEV}" ]; then
		HOST_VALIDATION=`echo $DEV | grep $HOSTNAME | wc -l`

		if [ $HOST_VALIDATION != $TRUE ]; then
			return 0
		else
			echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
			eval $OPERATION
			return 0
		fi
	elif [ $HOSTNAME == $HOST_INFORMED ]; then
		echo "[info] Executando o comando \"$OPERATION\" no host '`hostname -s`'..."
		eval $OPERATION
		return 0	
	fi
}


# ######################################################################
# TODO - ESTA FUNCAO NAO ESTA FINALIZADA
# realiza o backup da origem informada para o destino informado
# $1 - operacao (copy, remove)
# $2 - origem path
# $3 - destino path
# $4 - backup path
myBackup() {
	local operation=$1
	local sourcePath=$2
	local targetPath=$3
	local backupPath=$4

	local _=$1
	local _PATH=$2
	local _FILE=$( basename "$_PATH" )
	local DIR=$( dirname "$_PATH" )

	echo ""
	myEcho 0 info S "[myBackup] Criando backup de '$_PATH'"
	
	if [ ! -d "$GLO_BACKUPDIR/$DIR" ]; then
		mkdir -p  "$GLO_BACKUPDIR/$DIR"
	fi

	myEcho 0 debug S "cp  -fp  $DIR/$_FILE   $GLO_BACKUPDIR/$DIR"
	cp  -fp  "$DIR/$_FILE"   "$GLO_BACKUPDIR/$DIR"
	
	addToUninstallList "$operation"  "$GLO_BACKUPDIR/$_PATH"     "$DIR"
	# addToUninstallList  copy    "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
	# addToUninstallList  remove  "$sourceCommandLine"  "$removePath"
}


# ######################################################################
# EXCLUI ARQUIVOS DO DIRETORIO TEMPORARIO
removeTmpFiles() {
	# --- exclui temporarios
	echo ""
	myEcho 0 info S "Excluindo arquivos temporarios ($GLO_TMPDIR)..."
	rm -rf "$GLO_TMPDIR"/*.*
	return $?
}