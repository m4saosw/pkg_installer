#!/bin/sh
#############################################################################
# INSTALLER PACKAGE
# CORE LIBRARY
# massao
#############################################################################


# ######################################################################
# CARREGA OS ATRIBUTOS DO ARQUIVO DE CONFIGURACAO PARA VARIAVEIS GLOBAIS
load_VarInstallerProperties() {
	# carrega arquivos de configuracao	
	
	local cfgFile="installer.properties"
	local cfgFileList=$( cleanComments "$cfgFile" )

	# --- carrega atributos de configuracao do arquivo de configuracao de instalacao
	if [ -f "$cfgFile" ]; then
		
		GLO_EMULATE_ROOT_PATH=$(   echo "$cfgFileList"  |  grep "emulate.root_path"          |  awk -F "=" {'print $2'} )
		
		GLO_EMULATE_HOSTNAME=$(    echo "$cfgFileList"  |  grep "emulate.hostname"           |  awk -F "=" {'print $2'} )
		
		GLO_EMULATE_SYSTEM_PATH=$( echo "$cfgFileList"  |  grep "emulate.system_path"           |  awk -F "=" {'print $2'} )

		GLO_SHOW_DEBUG_MESSAGES=$( echo "$cfgFileList"  |  grep "screen.showDebugMessages"   |  awk -F "=" {'print $2'}  |  tr '[a-z]' '[A-Z]' )
		
		GLO_SHOW_COLOR_MESSAGES=$( echo "$cfgFileList"  |  grep "screen.showColorInMessages" |  awk -F "=" {'print $2'}  |  tr '[a-z]' '[A-Z]' )
		
		GLO_PROCESS_BACKUP_CONTINUEONERROR=$( echo "$cfgFileList"   |  grep "process.backup.continueOnError"  |  awk -F "=" {'print $2'}  |  tr '[a-z]' '[A-Z]' )

		GLO_PROCESS_INSTALL_CONTINUEONERROR=$( echo "$cfgFileList"  |  grep "process.install.continueOnError" |  awk -F "=" {'print $2'}  |  tr '[a-z]' '[A-Z]' )

		echo ""
		myEcho 0 debug S "Configuracao da instalacao ($cfgFile):"
		myEcho 1 debug S "$cfgFileList"		
	else
		myEcho 0 warn S "Arquivo de configuracao da instalacao ($cfgFile) nao encontrado."
	fi	
}






# ######################################################################
listTree() {
	# entrada: nenhuma
	# saida:  lista na saida padrao

	#local tree=$(cat $INSTALLATION_PACKAGE_DIR/estrutura.txt)
	
	# encontra os nos folhas da estrutura
	# busca a partir da pasta files
	local tree=$(find ./files  |  awk '$0 !~ last "/" {print last} {last=$0} END {print last}'  |  sort)
	
	# TODO - verificar se continua trazendo sempre as duas sub-estruturas
	#echo "$tree" | listTreeCommands 
	#echo "$tree" | listTreeAditional
	echo "$tree"
}


# ######################################################################
# RETORNA SOMENTE AS LINHAS DE COMANDOS  (JA EM ORDEM DE PRIORIDADE DE EXECUCAO)
# Atencao: o retorno pode conter tipos de comandos invalidos
listTreeCommands() {
	# entrada: via stdin - lista de estrutura de diretorios
	# saida:  lista de comandos na stdout
	# ATENCAO: nao imprimir nada na saida padrao. A funcao chamadora (que usa pipe) espera receber somente uma lista de instrucoes
	
	local varListTree=$(</dev/stdin)
	
	# cria um arquivo auxiliar (com timestamp para evitar problemas com multi-thread)
	local tmpfile=$( getTmpFilename "listTreeCommands" )
	
	local cmdList='{remove_file}  {remove_dir}  {remove_all}  {copy}  {copy_instance}  {modify}'  # lista comandos em ordem de prioridade de execucao

	# le as entradas, e caso seja comando, adiciona em um arquivo temporario
	#while read line; do
		# ATENCAO: troque aqui como pegar se e command ou nao
	#	strCmd=$( echo $line  |  awk -F/ '{ print $4 }'  |  tr '[A-Z]' '[a-z]' )
		
		# se for commands
	#	if [ "$strCmd" == "commands" ]; then		
	#		echo $line  >>  "$tmpfile"
	#	fi
	#done
	

	echo "$varListTree"  |  grep "^./.*/commands/"  >>  "$tmpfile"
	
	# se arquivo tem conteudo
	if [[ -s "$tmpfile" ]] ; then
	
		# busca os comandos no arquivo temporario, seguindo uma prioridade de execucao, e devolve na ordem de prioridade
		# imprime lista conforme a prioridade de execucao de comandos
		for cmd in $cmdList; do
			# cat $tmpfile  |  egrep $cmd  #- menos performance
			egrep "$cmd"  "$tmpfile"
		done
		
		local cmdValidList='({remove_file})|({remove_dir})|({remove_all})|({copy})|({modify})'  # lista de comandos validos
		# imprime ao final uma relacao dos comandos nao validos
		egrep -v  "$cmdValidList"  "$tmpfile"
	fi
	
	# rm -rf "$tmpfile"
}


# ######################################################################
# RETORNA SOMENTE AS LINHAS ADITIONAL
# Atencao: o retorno pode conter tipos de comandos invalidos
listTreeAditional() {
	# entrada: via stdin - lista de estrutura de diretorios
	# saida:  lista de comandos na stdout
	
	#while read line; do
		# ATENCAO: troque aqui como pegar se e command ou nao
	#	strCmd=$( echo $line  |  awk -F/ '{ print $4 }'  |  tr '[A-Z]' '[a-z]' )
		
		# se for aditional
	#	if [ "$strCmd" == "aditional" ]; then		
	#		echo $line
	#	fi
	#done
	
	local varListTree=$(</dev/stdin)
	echo "$varListTree"  |  grep "^./.*/aditional/"
}



# ######################################################################
listParsed() {
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		getListLineParsed "$line"
	done
}



# ######################################################################
# REALIZA O PARSING DA LINHA - ABRANGE AS TAGS POSTERIORES AO TIPO DE COMANDO  (SAO AS TAGS DE PATH)
getListLineParsed() {
	# entrada: $1 - linha
	# saida:  lista na stdout
	
	local line="$1"
	
	# TODO - transferir o carregamento destas propriedades para fora desta funcao e fazer mecanismo de leitura de arquivo properties
	#local product_path='/opt/ptin/acm'
	local engine_path=` grep "acm.engine.path" "$GLO_SYSTEM_FILE"  |  awk -F "=" {'print $2'}`
	local product_path=$( dirname "$engine_path" )    # obs - este path nao existe, tive que fazer isso - cuidado perigoso
	

	# TODO - falta inserir tratamento para nomes com espacos
	local engine_instance_path=` basename $( grep "engine.inst.1.path" "$GLO_SYSTEM_FILE"  |  awk -F "=" {'print $2'} )`  # pega somente o numero da instancia

	
	local s="$line"	
	# OBSERVACAO - Ha outro metodo Replace Value of Variable, mas nao funcionou ${variable//search/replace}

	# a conversao sera feita somente sobre 1 ocorrencia. Objetivo e de identificar ao final anormalidades apos o parsing. delimitador #
	
	# ==== {product_path}
	s=`echo "$s"  |  sed "s#{product_path}#$product_path#"`
	
	# ==== {engine_path}
	s=`echo "$s"  |  sed "s#{engine_path}#$engine_path#"`
	
	# ==== {engine_instance_path}
	s=`echo "$s"  |  sed "s#{engine_instance_path}#$engine_instance_path#"`
	
	# ==== {allinstances}
	local num=` echo $line  |  grep "{allinstances}" | wc -l `
	if [ $num -eq 1 ]; then
		# ***** loop em todas instancias do engine (1 a n  e  tambem a instance)
		local listNumInstances=` grep "engine.inst.*.path" $GLO_SYSTEM_FILE | awk -F "=" {'print $2'}`
		#listNumInstances=$(echo -e  "$listNumInstances\ninstance")  #  inclui a pasta instance
		listNumInstances=$(echo -e  "$listNumInstances")  #  nao inclui a pasta instance
		
		for instance in $listNumInstances; do 
			local num_instance=`basename "$instance"`
			echo "$s"  |  sed "s#{allinstances}#$num_instance#"  |  cleanPath
		done;
	else
		# nao tem {allinstances}
		echo "$s"  |  cleanPath
	fi
}


# ######################################################################
# TODO - pendente
getAmbiente() {
	# entrada: via stdin - lista de estrutura de comandos
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		# OBSERVACAO - alterar aqui a maneira como pega o ambiente
		echo $line  |  awk -F/ '{ print $5 }'
	done
	# aqui poderia talvez ja validar se o ambiente corrente confere com o ambiente passado e retornar true ou false
}


# ######################################################################
# OBTEM O HOSTNAME DA LINHA INFORMADA
getHostName() {
	# entrada: via stdin - lista de estrutura de comandos
	# saida:   via stdout - lista de hostnames
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		# OBSERVACAO - alterar aqui a maneira como pega o host
		echo $line  |  awk -F/ '{ print $6 }'
	done
	# aqui poderia talvez ja validar se o ambiente corrente confere com o ambiente passado e retornar true ou false
}


# ######################################################################
# OBTEM O HOSTNAME DA MAQUINA CORRENTE OU ENTAO O HOSTNAME EMULADO
# retorno: string 
getCurrentHostName() {
	if [ "$GLO_EMULATE_HOSTNAME" != "" ]; then
		echo "$GLO_EMULATE_HOSTNAME"
	else
		echo $( hostname -s )
	fi
}


# ######################################################################
# OBTEM A TAG COMANDO DA INSTRUCAO
# retorno: string 
getListCommand() {
	# entrada: via stdin - lista de estrutura de comandos
	# saida:   via stdout - lista de tag command
	
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		# OBSERVACAO - alterar aqui a maneira como pega o host
		echo $line  |  awk -F/ '{ print $7 }'
	done
}


# ######################################################################
# LISTA AS INSTRUCOES QUE PERTENCEM AO ESCOPO DE EXECUCAO, ISTO E, SE TAGS HOST SAO COMPATIVEIS COM O HOST CORRENTE
listExecutionScope() {
	# entrada: stdin - arvore de diretorios
	# saida:  lista na stdout
	
	#local varListTreeCommands=$(</dev/stdin)
	
	local listHostsFile=$( cleanComments  "hosts.properties" )
	
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		# TODO - verificar o ambiente
		# local ambiente=$( echo "$line"  |  getAmbiente )
		
		# obtem o hostname da instrucao corrente
		local hostToExecute=$( echo "$line"  |  getHostName )	
		#myEcho  0 debug S " "   >&2
		#myEcho  0 debug S "host da instrucao=$hostToExecute"   >&2
		
		local listHostNamesParsed=$( getHostNamesParsed  "$hostToExecute"  "$listHostsFile" )
		#myEcho 0 debug S "listHostNamesParsed=$listHostNamesParsed"   >&2
		
		# imprime a linha caso ela contenha a tag host name 
		# TODO - esta comparacao abaixo nao funciona!!! nao sei o por que? A alternativa grep nao e tao segura
		if [ "$listHostNamesParsed" == "*" ]; then
			echo "$line"
		else
			local currentHostName=$( getCurrentHostName )
			#myEcho 0 debug S "currentHostName=$currentHostName"   >&2
			
			local itemDataList
			for itemDataList in $listHostNamesParsed; do
				# imprime a linha caso ela faca parte do escopo de execucao, e sai da validacao da lista
				# validacao compara equivalencia pois o grep seria inseguro
				if [ "$itemDataList" == "$currentHostName" ]; then
					echo "$line"
					break
				fi
			done
		fi
	done
}



# ######################################################################
# RETORNA LISTA DE ESTRUTURA CUJOS TIPOS DE COMANDOS SAO INVALIDOS
validation_GetListCmdTypesInvalids() {
	# entrada: via stdin - lista de estrutura de comandos
	# saida:  lista na stdout
	# ATENCAO: nao imprimir nada na saida padrao. A funcao chamadora espera receber somente um print com os comandos invalidos

	local tmpfile=$( getTmpFilename "validation_GetListCmdTypesInvalids" )
	local msg="Comando invalido em: "
	local cmdList="({remove_file})|({remove_dir})|({remove_all})|({copy})|({modify})"  # lista de comandos validos
	
	# commands: {skip_backup}
	# aditional: {files} {run_sh}  
	
	# TODO - verificar uma forma melhor de verificar se tem ocorrencias (sem ter que criar arquivo temporario ou loop)
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
   	   	# lista ocorrencias invalidas
		echo $line  |  egrep -v  $cmdList  |  listEchoError "$msg" >>  $tmpfile
	done
	
	# === verifica ocorrencias no arquivo temporario (file not empty)
	local result=$GLO_SUCCESS
	if [[ -s "$tmpfile" ]] ; then
		result=$GLO_ERROR
	fi
	
	cat $tmpfile 
	#rm -f "$tmpfile"

	return $result
}


# ######################################################################
# retorna lista de estrutura de comandos que tem argumentos invalidos
validation_GetListCmdArgumentsInvalids() {
	# entrada: via stdin - lista de estrutura de comandos
	# saida:  lista na stdout
	# OBS: sempre que tiver erro colocar result=$GLO_ERROR
	
	# ATENCAO: nao imprimir nada na saida padrao. A funcao chamadora espera receber somente um print com os argumentos invalidos
	
	#local tmpfile=tmp_file_validation_GetListCmdArgumentsInvalids_"$(getTimestamp)".tmp
	local msg="Argumento invalido: "

	#rm -f "$tmpfile"

	#myEcho 0 info S "Localizando argumentos invalidos dos comandos..."
	
	
	local varListTreeCommands=$(</dev/stdin)
	local varListTargetPath
	local result=$GLO_SUCCESS
	
	# === iterando pela lista de comandos origem
	for sourceCommandLine in $varListTreeCommands; do
		# echo
		# myEcho 1 info S "Lendo Origem $sourceCommandLine"
		
		# TODO - poderia fazer a validacao do tipo de comando aqui ao inves de um metodo a parte
		
		varListTargetPath=$( echo "$sourceCommandLine"  |  listParsed  |  listTargetPath )
		#myEcho 1 debug S "varListTargetPath=$varListTargetPath"
				
		# === iterando pela lista de comandos destino (pode ser 1 -> 1  ou  1 -> N)
		for targetPath in $varListTargetPath; do
			
			# verifica se tem tags cujo parsing nao foi aplicado
			invalidTagTargetPath=$( echo "$targetPath"  |  grep "{.*}" )
			if [[ "$invalidTagTargetPath" != "" ]]; then
				myEcho 1 error S "$invalidTagTargetPath - ha tags invalidas/repetidas na mesma instrucao"
				result=$GLO_ERROR
			fi

			# verifica se a entrada esta dentro do escopo de execucao deste host
			local varExecutionScope=$( echo $sourceCommandLine  |  listExecutionScope )			
			if [[ "$varExecutionScope" != "" ]]; then
					# obtem o tipo de comando
					local command="$( echo "$sourceCommandLine"  |  getListCommand )"

					if [[ "$command" == "{remove_file}" ]]; then

						if [ ! -f "$targetPath" ]; then
							myEcho 1 warn S "$targetPath - arquivo nao existe no Destino"  >&2
						else
							myEcho 1 debug S "OK"  >&2
						fi
						
						
					elif [[ "$command" == "{remove_dir}" ]]; then
					
						if [ ! -d "$targetPath" ]; then
							myEcho 1 warn S "$targetPath - diretorio nao existe no Destino"  >&2
						else
							myEcho 1 debug S "OK"  >&2
						fi

						
					elif [[ "$command" == "{remove_all}" ]]; then
						
						if [ ! -d "$targetPath" ]; then
							myEcho 1 warn S "$targetPath - diretorio nao existe no Destino"  >&2
						else
							myEcho 1 debug S "OK"  >&2
						fi


					elif [[ "$command" == "{copy}" ]]; then
						
						# verifica se nao existe no Destino
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								myEcho 1 warn S "$targetPath - arquivo nao existe no Destino"  >&2
								
							# se for diretorio
							elif [ -d "$sourceCommandLine" ]; then
								myEcho 1 warn S "$targetPath - diretorio nao existe no Destino"  >&2
							
							else
								myEcho 1 error S "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
						else
							myEcho 1 debug S "OK"  >&2
						fi

						
					elif [[ "$command" == "{modify}" ]]; then
						
						# verifica se nao existe no Destino
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								#myEcho 1 error S "$targetPath - arquivo nao existe no Destino"
								#result=$GLO_ERROR
								
								myEcho 1 warn S "$targetPath - arquivo nao existe no Destino"  >&2
								
							else
								myEcho 1 error S "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
						else
						
							#  obtem a lista de comandos sem linhas de comentarios
							local listCommands=$( cleanComments "$sourceCommandLine"  |  sed "s,\$FILE,$targetPath,g" )
							
							# se ha lista de comandos (tem conteudo)
							if [[ "$listCommands" == "" ]]; then
								myEcho 2 error S  "$sourceCommandLine - nao existem comandos dentro do arquivo"
								result=$GLO_ERROR
								break
							else
								myEcho 2 info S "Listando comandos dentro do arquivo:"  >&2
								myEcho 2 info S "$listCommands"  >&2
							fi
						fi
						
					else
						myEcho 1 error S "$command - comando invalido!"
						result=$GLO_ERROR
					fi
			else
				myEcho 1 debug S "Validacao pulada. Instrucao para outro host"  >&2
			fi
		done
		
		# mostra erro caso esteja faltando argumentos pos-comando
		if [ "$varListTargetPath" == "" ]; then
			myEcho 1 error S "$sourceCommandLine  - comando sem argumentos"
			result=$GLO_ERROR
		fi

	done
	
	###############
	
	# cat $tmpfile
	
	# === verifica ocorrencias no arquivo temporario (file not empty)
	#local result=$GLO_SUCCESS
	#if [[ -s "$tmpfile" ]] ; then
	#	result=$GLO_ERROR
	#fi

	#rm -f "$tmpfile"

	return $result
}


# ######################################################################
# ANTIGO
etapa1PreValidacao_() {
	myEcho 0 info S "[validacao] Executando etapa Validacao..."
	myEcho 0 info S "Carregando arvore de diretorios..."
	local varListTree=$( listTree )
	myEcho 1 debug S "$varListTree"

	myEcho 0 info S "Lendo arvore de Comandos..."	
	local varListTreeCommands=$( echo "$varListTree"  |  listTreeCommands )
	myEcho 1 info S "$varListTreeCommands"	
	
	#GLO_STATUSCMD=$(validation_GetListCmdTypesInvalids)    OBS: desse modo funciona mas os echos nao ficam um por linha
	echo ""
	myEcho 0 info S "[validacao] Arvore de Comandos - Listando tipos de comandos invalidos..."
	echo "$varListTreeCommands"  |  validation_GetListCmdTypesInvalids
	GLO_STATUSCMD=$?	
	echo $GLO_STATUSCMD
	#continueOnStatusCmdError
	
	echo ""
	myEcho 0 info S "[validacao] Arvore de Comandos - Listando comandos com argumentos invalidos... host corrente"
	echo "$varListTreeCommands"  |  validation_GetListCmdArgumentsInvalids
	GLO_STATUSCMD=$?
	echo validation_GetListCmdArgumentsInvalids GLO_STATUSCMD=$GLO_STATUSCMD
	#continueOnStatusCmdError

	# TODO - exibir lista comandos parsed (somente host corrente), apenas para informacao
	#echo ""
	#myEcho 0 info S "[validacao] Arvore de Comandos - listando lista de comandos final - parsed"
	#echo "$varListTreeCommands"  |  listExecutionScope  |  listParsed  |  listEchoInfo
	#GLO_STATUSCMD=$?
	#continueOnStatusCmdError
	
	return $result
}


# ######################################################################
etapa1PreValidacao() {
	echo ""
	myEcho 0 info T1 "[validacao] Executando etapa Validacao. Analisando estrutura da instalacao..."
	echo ""
	myEcho 0 info S "Carregando arvore de diretorios..."
	local varListTree=$( listTree )
	#myEcho 1 debug S "$varListTree"

	echo ""
	myEcho 0 info S "Lendo arvore de Comandos..."	
	local varListTreeCommands=$( echo "$varListTree"  |  listTreeCommands )
	myEcho 1 info S "$varListTreeCommands"
	
	local _validation_GetListCmdTypesInvalids
	local result=$GLO_SUCCESS
	
	echo ""
	myEcho 0 info S "Analisando arvore de Comandos..."
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		echo ""
		myEcho 1 info S "Instrucao $line"

		local _listParsed=$( echo "$line"  |  listExecutionScope  |  listParsed )
		
		local _validation_GetListCmdTypesInvalids=$( echo "$line"  |  validation_GetListCmdTypesInvalids )
		# TODO - tratar o codigo de saida do erro
		#GLO_STATUSCMD=$?
		#GLO_STATUSCMD=${PIPESTATUS[1]}  nao funciona!!!
		#myEcho 0 debug S "GLO_STATUSCMD validation_GetListCmdTypesInvalids=$GLO_STATUSCMD"
		
		local _validation_GetListCmdArgumentsInvalids=$( echo "$line"  |  validation_GetListCmdArgumentsInvalids )
		# TODO - tratar o codigo de saida do erro
		#GLO_STATUSCMD=$?
		#GLO_STATUSCMD=${PIPESTATUS[1]}  nao funciona!!!
		#myEcho 0 debug S "GLO_STATUSCMD validation_GetListCmdArgumentsInvalids=$GLO_STATUSCMD"
		
		
		if [[ ("$_listParsed" != "") ]]; then
			if [[ ("$line" != "$_listParsed") ]]; then
				myEcho 2 info S "Instrucao convertida em:"
				myEcho 3 info S "$_listParsed"
			fi
		else
			myEcho 2 debug S "Conversao pulada. Instrucao para outro host"			
		fi

		if [[ ("$_validation_GetListCmdTypesInvalids" == "") && ("$_validation_GetListCmdArgumentsInvalids" == "") ]]; then
			myEcho 2 info S "OK"
		else
			#myEcho 2 info S "Validando..."
			result=$GLO_ERROR
			
			if [ "$_validation_GetListCmdTypesInvalids" != "" ]; then
				#myEcho 2 warn S "Comandos invalidos:"
				myEcho 2 none S "$_validation_GetListCmdTypesInvalids"
				#myEcho 2 info S "_validation_GetListCmdTypesInvalids=$_validation_GetListCmdTypesInvalids"
			fi		
			
			if [ "$_validation_GetListCmdArgumentsInvalids" != "" ]; then
				#myEcho 2 warn S "Tags de path invalidas:"
				myEcho 2 none S "$_validation_GetListCmdArgumentsInvalids"
				#myEcho 2 info S "_validation_GetListCmdArgumentsInvalids=$_validation_GetListCmdArgumentsInvalids"
			fi
		fi
	done <<< "$varListTreeCommands"
	
	

	# exibe lista comandos parsed (somente host corrente), apenas para informacao
	#echo
	#echo "[info] listando lista de comandos final - parsed"
	#myEcho 0 info S "Analisando arvore de diretorios..."
	#echo "$varListTreeCommands"  |  listExecutionScope  |  listParsed  |  listEchoInfo
	#GLO_STATUSCMD=$?
	#continueOnStatusCmdError
	
	return $result
}


# ######################################################################
# esta funcao e para uso futuro
# GERA UM ARQUIVO DE INSTRUCOES JA CONVERTIDAS (PARSED). NAO E REALIZADO AQUI VALIDACAO QUANTO A ARGUMENTOS E COMANDOS INVALIDOS
# baseado em etapa2Backup()  que foi baseado em validation_GetListCmdArgumentsInvalids()
generatePreprocessingFile() {
	local OPERATIONS_FILE=preprocessingFile.list
	local result=$GLO_SUCCESS
	
	myEcho 0 info S "[conversao] Criando arquivo de pre-processamento..."
	
	# TODO - trazer estas informacoes de fora, nao deixar aqui dentro
	local varListTree=$(listTree)

	local varListTreeCommands=$( echo "$varListTree"  |  listTreeCommands )

	local tmpfile=$( getTmpFilename "generatePreprocessingFile" )

	rm -f "$OPERATIONS_FILE"

	#local varListTreeCommands=$(</dev/stdin)
	local varListTargetPath
	
	# === iterando pela lista de comandos origem
	# CUIDADO se colocar "$varListTreeCommands" entre parenteses da problema!
	for sourceCommandLine in $varListTreeCommands; do
		myEcho 1 debug S " "
		myEcho 1 debug S "Lendo Origem $sourceCommandLine"
		
		varListTargetPath=$( echo "$sourceCommandLine"  |  listParsed  |  listTargetPath )
				
		# === iterando pela lista de comandos destino (pode ser 1 -> 1  ou  1 -> N)
		# CUIDADO se colocar "$varListTargetPath" entre parenteses da problema!
		for targetPath in $varListTargetPath; do
			#myEcho 2 debug S "Adicionando $targetPath"
			
			# verifica se a entrada esta dentro do escopo de execucao deste host
			#local varExecutionScope=$( echo $sourceCommandLine  |  listExecutionScope )
			#if [[ "$varExecutionScope" != "" ]]; then

				local command="$( echo "$sourceCommandLine"  |  getListCommand )"
				addToPreprocessingFile "$command"  "$sourceCommandLine"  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
				# TODO - tratar o codigo de saida do erro
				GLO_STATUSCMD=$?
			#fi
		done
	done
	
	
	
	###############
	
	# cat $tmpfile
	
	# === verifica ocorrencias no arquivo temporario (file not empty)
	if [[ -s "$tmpfile" ]] ; then
		result=$GLO_ERROR
	fi

	return $result
}


# ######################################################################
# RETORNA A SUBSTRING QUE VEM APOS O COMANDO
listTargetPath() {
	local line   # importante usar para nao misturar dados com algum outro processo concorrente
	while read line; do
		# retorna a substring que vem apos o comando
		local targetPath=$( echo "$line"  |  awk 'match($0,"{remove_file}|{remove_dir}|{remove_all}|{copy}|{modify}"){print substr($0,RSTART+RLENGTH)}' )
		if [ "$targetPath" != "" ]; then
			echo $GLO_EMULATE_ROOT_PATH$targetPath  |  cleanPath
		fi
	done
}


# ######################################################################
# versao antiga - nao esta sendo usado
getTargetPath() {
	local line=$1
	#local pattern='{remove_file}|{remove_dir}|{copy}|{modify}'
	#echo "aaaa{copy}/opt/ptin/acm" | awk 'match($0,"{copy}"){print substr($0,RSTART+RLENGTH)}'
	
	# retorna a substring que vem apos o comando
	echo "$line"  |  awk 'match($0,"{remove_file}|{remove_dir}|{remove_all}|{copy}|{modify}"){print substr($0,RSTART+RLENGTH)}'
}


# ######################################################################
etapa2Backup() {
	myEcho 0 info T1 "[backup] Executando etapa Backup..."
	
	# TODO - trazer estas informacoes de fora, nao deixar aqui dentro
	local varListTree=$(listTree)
	local varListTreeCommands=$( echo "$varListTree"  |  listTreeCommands )

#validation_GetListCmdArgumentsInvalids() {
	# entrada: via stdin - lista de estrutura de comandos
	# saida:  lista na stdout
	
	local result=$GLO_SUCCESS
	local tmpfile=$( getTmpFilename "etapa2Backup" )
	#local msg="Encontrado argumento invalido: "

	rm -f "$GLO_UNINSTALL_FILE"

	#local varListTreeCommands=$(</dev/stdin)
	local varListTargetPath
	
	# === iterando pela lista de comandos origem
	# CUIDADO se colocar "$varListTreeCommands" entre parenteses da problema!
	for sourceCommandLine in $varListTreeCommands; do
		echo
		myEcho 1 info S "Lendo Origem $sourceCommandLine"
		
		varListTargetPath=$( echo "$sourceCommandLine"  |  listParsed  |  listTargetPath )
				
		# === iterando pela lista de comandos destino (pode ser 1 -> 1  ou  1 -> N)
		# CUIDADO se colocar "$varListTargetPath" entre parenteses da problema!
		for targetPath in $varListTargetPath; do
			
			# verifica se tem tags cujo parsing nao foi aplicado
			#invalidTagTargetPath=$( echo "$targetPath"  |  grep "{.*}" )
			#if [[ "$invalidTagTargetPath" != "" ]]; then
			#	echo "[error] $invalidTagTargetPath - tags invalidas nos argumentos"
			#fi
			
			# verifica se a entrada esta dentro do escopo de execucao deste host
			local varExecutionScope=$( echo $sourceCommandLine  |  listExecutionScope )
			if [[ "$varExecutionScope" != "" ]]; then
					# obtem o tipo de comando
					# TODO - no momento estou considerando apenas 1 comando
					local command="$( echo "$sourceCommandLine"  |  getListCommand )"
					
					if [[ "$command" == "{remove_file}" ]]; then
						
						if [ ! -f "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - arquivo nao existe no Destino"
						else
							myEcho 2 info S "Backup Origem $targetPath   Destino --->  $GLO_BACKUPDIR"
							myEcho 2 debug S "cp -rfp --parents  $targetPath  $GLO_BACKUPDIR"
							
							cp -rfp --parents  "$targetPath"  "$GLO_BACKUPDIR"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
							
							# adiciona na lista de desinstalacao - recriar							
							addToUninstallList "copy"  "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{remove_dir}" ]]; then
					
						if [ ! -d "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - diretorio nao existe no Destino"
						else
							myEcho 2 info S "Backup Origem $targetPath   Destino --->  $GLO_BACKUPDIR"
							myEcho 2 debug S  "cp -rfp --parents  $targetPath  $GLO_BACKUPDIR"
							
							cp -rfp --parents  "$targetPath"  "$GLO_BACKUPDIR"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
							
							# adiciona na lista de desinstalacao - recriar
							addToUninstallList "copy"  "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{remove_all}" ]]; then
					
						if [ ! -d "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - diretorio nao existe no Destino"
						else
							myEcho 2 info S "Backup Origem $targetPath   Destino --->  $GLO_BACKUPDIR"
							myEcho 2 debug S  "cp -rfp --parents  $targetPath  $GLO_BACKUPDIR"
							
							cp -rfp --parents  "$targetPath"  "$GLO_BACKUPDIR"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
							
							# TODO - colocar a definicao da lista de uninstall certa para essa tag
							# adiciona na lista de desinstalacao - recriar
							addToUninstallList "copy"  "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{copy}" ]]; then
					
						# verifica se nao existe no Destino  (novo arquivo/diretorio)
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								myEcho 2 warn S  "$targetPath - arquivo nao existe no Destino"
								
							# se for diretorio
							elif [ -d "$sourceCommandLine" ]; then
								myEcho 2 warn S  "$targetPath - diretorio nao existe no Destino"

							else
								myEcho 2 error S  "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
								
							# loop para verificar o que deve ser removido na desinstalacao (do no folha para o mais interno)
							local addToList
							local removePath=$targetPath							
							while [ ! -e "$removePath" ]; do
								addToList="addToUninstallList remove  \"$sourceCommandLine\"  \"$removePath\""
								
								removePath=$( dirname "$removePath" )
							done
							
							# adiciona na lista somente o mais interno
							if [ "$addToList" != "" ]; then
								eval "$addToList"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 3"; }
							fi
							
						else # existe no Destino (sobrescrever)
							
							myEcho 2 info S "Backup Origem $targetPath   Destino --->  $GLO_BACKUPDIR"
							myEcho 2 debug S  "cp -rfp --parents  $targetPath  $GLO_BACKUPDIR"	
							
							cp -rfp --parents  "$targetPath"  "$GLO_BACKUPDIR"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
							
							addToUninstallList "copy"  "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{modify}" ]]; then
					
							# verifica se nao existe no Destino
							if [ ! -e "$targetPath" ]; then
								# se for arquivo
								if [ -f "$sourceCommandLine" ]; then
									myEcho 1 error S "$targetPath - arquivo nao existe no Destino"
									result=$GLO_ERROR
									
								else
									myEcho 1 error S "Nao e um arquivo regular!"
									result=$GLO_ERROR
								fi
							else
							
								#  obtem a lista de comandos sem linhas de comentarios e com substituicao da variavel $FILE pelo valor devido
								local listCommands=$( cleanComments "$sourceCommandLine"  |  sed "s,\$FILE,$targetPath,g" )
								
								# se ha lista de comandos (tem conteudo)
								if [[ ! "$listCommands" == "" ]]; then
									# faz backup do arquivo
									myEcho 2 info S "Backup Origem $targetPath   Destino --->  $GLO_BACKUPDIR"
									myEcho 2 debug S  "cp -rfp --parents  $targetPath  $GLO_BACKUPDIR"
									
									cp -rfp --parents  "$targetPath"  "$GLO_BACKUPDIR"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
									
									addToUninstallList "copy"  "$sourceCommandLine"  "$targetPath"  "$GLO_BACKUPDIR/$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
								else
									myEcho 2 error S  "$sourceCommandLine - nao existem comandos dentro do arquivo"
									result=$GLO_ERROR
									break
								fi
							fi
							
					else
						myEcho 2 error S "$command - comando invalido!"
						result=$GLO_ERROR
					fi
			else
				myEcho 2 debug S "Backup pulado. Instrucao para outro host"
			fi
		done
		
		# mostra erro caso esteja faltando argumentos pos-comando
		if [ "$varListTargetPath" == "" ]; then
			myEcho 2 error S "$sourceCommandLine  - comando sem argumentos"
			result=$GLO_ERROR
		fi
	done
	
	
	
	###############
	
	# cat $tmpfile
	
	# === verifica ocorrencias no arquivo temporario (file not empty)
	if [[ -s "$tmpfile" ]] ; then
		result=$GLO_ERROR
	fi

	#rm -f "$tmpfile"

	return $result
}




# ######################################################################
etapa3Install() {
	myEcho 0 info T1 "[instalacao] Executando etapa Instalacao..."
	
	local result=$GLO_SUCCESS
	
	# TODO - trazer estas informacoes de fora, nao deixar aqui dentro
	local varListTree=$(listTree)
	local varListTreeCommands=$( echo "$varListTree"  |  listTreeCommands )

	local tmpfile=$( getTmpFilename "etapa3Install" )
	#local msg="Encontrado argumento invalido: "

	#local varListTreeCommands=$(</dev/stdin)
	local varListTargetPath
	
	# === iterando pela lista de comandos origem
	# CUIDADO se colocar "$varListTreeCommands" entre parenteses da problema!
	for sourceCommandLine in $varListTreeCommands; do
		echo
		myEcho 1 info S "Lendo Origem $sourceCommandLine"
		
		varListTargetPath=$( echo "$sourceCommandLine"  |  listParsed  |  listTargetPath )
				
		# === iterando pela lista de comandos destino (pode ser 1 -> 1  ou  1 -> N)
		# CUIDADO se colocar "$varListTargetPath" entre parenteses da problema!
		for targetPath in $varListTargetPath; do
			
			# verifica se tem tags cujo parsing nao foi aplicado
			#invalidTagTargetPath=$( echo "$targetPath"  |  grep "{.*}" )
			#if [[ "$invalidTagTargetPath" != "" ]]; then
			#	echo "[error] $invalidTagTargetPath - tags invalidas nos argumentos"
			#fi
			
			# verifica se a entrada esta dentro do escopo de execucao deste host
			local varExecutionScope=$( echo $sourceCommandLine  |  listExecutionScope )
			if [[ "$varExecutionScope" != "" ]]; then
					# obtem o tipo de comando
					# TODO - no momento estou considerando apenas 1 comando
					local command="$( echo "$sourceCommandLine"  |  getListCommand )"
			
					if [[ "$command" == "{remove_file}" ]]; then
						
						if [ ! -f "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - arquivo nao existe no Destino"
						else
							myEcho 2 info S  "Excluindo $targetPath"
							myEcho 2 debug S  "rm -rf  $targetPath"
							
							rm -rf  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi
						
					elif [[ "$command" == "{remove_dir}" ]]; then
					
						if [ ! -d "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - diretorio nao existe no Destino"
						else
							myEcho 2 info S  "Excluindo $targetPath"
							myEcho 2 debug S  "rm -rf  $targetPath"
							
							rm -rf  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{remove_all}" ]]; then
					
						if [ ! -d "$targetPath" ]; then
							myEcho 2 warn S "$targetPath - diretorio nao existe no Destino"
						else
							myEcho 2 info S  "Excluindo $targetPath/*"
							myEcho 2 debug S  "rm -rf  $targetPath/*"							
							myEcho 2 debug S  "find $targetPath -maxdepth 1 -iname ".*" -exec rm -rf {} \;"
							
							# wildcards necessita ser executado so apos conversao  (inclui tambem arquivos e diretorios ocultos)
							eval "rm -rf  $targetPath/*"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
							# excluindo ocultos  - nao encontrei uma forma de usar apenas o rm
							eval "find $targetPath -maxdepth 1 -iname \".*\" -exec rm -rf {} \\;"  ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

						
					elif [[ "$command" == "{copy}" ]]; then
					
						# verifica se nao existe no Destino
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								myEcho 2 warn S  "$targetPath - arquivo nao existe no Destino"
								myEcho 2 debug S  "mkdir -p $( dirname "$targetPath")"
								
								mkdir -p "$( dirname "$targetPath")"  # compativel com nomes com espacos
								# TODO - fazer o controle do retorno do comando
								GLO_STATUSCMD=$?
								
							# se for diretorio
							elif [ -d "$sourceCommandLine" ]; then
								myEcho 2 warn S  "$targetPath - diretorio nao existe no Destino. Criando..."
								#myEcho 2 debug S  "mkdir -p $targetPath"
								myEcho 2 debug S  "mkdir -p $( dirname "$targetPath")"
								
								#mkdir -p "$targetPath"
								mkdir -p "$( dirname "$targetPath")"  # compativel com nomes com espacos
								# TODO - fazer o controle do retorno do comando
								GLO_STATUSCMD=$?
								
							else
								myEcho 2 error S  "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
						else
							myEcho 2 debug S  "$targetPath - destino existente"
						fi
						
						myEcho 2 info S  "Copiando $sourceCommandLine  --->  $targetPath"
						myEcho 2 debug S  "cp -rf  $sourceCommandLine  $targetPath"
						
						cp -rf  "$sourceCommandLine"  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }

						
					elif [[ "$command" == "{modify}" ]]; then
					
							# verifica se nao existe no Destino
							if [ ! -e "$targetPath" ]; then
								# se for arquivo
								if [ -f "$sourceCommandLine" ]; then
									myEcho 1 error S "$targetPath - arquivo nao existe no Destino"
									result=$GLO_ERROR
									
								else
									myEcho 2 error S  "Nao e um arquivo regular!"
									result=$GLO_ERROR
								fi
							else
							
								#  obtem a lista de comandos sem linhas de comentarios e com substituicao da variavel $FILE pelo valor devido
								local listCommands=$( cleanComments "$sourceCommandLine"  |  sed "s,\$FILE,$targetPath,g")
								
								# se ha lista de comandos (tem conteudo)
								if [[ ! "$listCommands" == "" ]]; then
								#if [[ -s "$tmpfile" ]] ; then
									# faz backup do arquivo
									# echo "   [info] Backup    $targetPath"
									# cp -rf --parents  "$targetPath"  "$GLO_BACKUPDIR"
									# myEcho 1 debug S  "cp -rf --parents  $targetPath  $GLO_BACKUPDIR"
									# TODO - fazer o controle do retorno do comando
									# GLO_STATUSCMD=$?
									# echo $GLO_STATUSCMD	
									
									myEcho 2 info S  "Executando comandos contidos em $targetPath..."
									# itera pela lista de comandos
									local line   # importante usar para nao misturar dados com algum outro processo concorrente
									while read line; do
										# executa o comando																
										myEcho 3 info S  "Executando: $line"
										eval $line   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 3"; }
									done <<< "$listCommands"
									
								else
									myEcho 2 error S  "$sourceCommandLine - nao existem comandos dentro do arquivo"
									result=$GLO_ERROR
									break
								fi
							fi
							
					else
						myEcho 2 error S "$command - comando invalido!"
						result=$GLO_ERROR
					fi
			else
				myEcho 2 debug S "Instalacao pulada. Instrucao para outro host"
			fi
		done
		
		# mostra erro caso esteja faltando argumentos pos-comando
		if [ "$varListTargetPath" == "" ]; then
			myEcho 2 error S "$sourceCommandLine  - comando sem argumentos"
			result=$GLO_ERROR
		fi
	done
	
	
	
	###############
	
	# cat $tmpfile
	
	# === verifica ocorrencias no arquivo temporario (file not empty)
	if [[ -s "$tmpfile" ]] ; then
		result=$GLO_ERROR
	fi

	# rm -f "$tmpfile"

	return $result
}










# ######################################################################
# ADICIONA UMA ENTRADA DE ARQUIVO/DIRETORIO NA LISTA DE CONTROLE
addToUninstallList() {
	# $1 - operacao (copy, remove)
	# $2 - origem path
	# $3 - destino path
	# $4 - backup path
	
	local operation=$1
	local sourcePath=$2
	local targetPath=$3
	local backupPath=$4
	
	if [ ! -f "$GLO_UNINSTALL_FILE" ]; then
		myEcho 0 info S "Arquivo de lista de desinstalacao ($GLO_UNINSTALL_FILE) nao existe. Criando novo..."
		
		local dir=$(dirname "$GLO_UNINSTALL_FILE")
		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi
		
		touch "$GLO_UNINSTALL_FILE"
	fi
	
	# obtem o ultimo sequence
	# TODO - otimizar este comando para utilizar apenas 1 awk
	local last_sequence=$( awk 'END{print}' $GLO_UNINSTALL_FILE   |  awk -F "{SEQUENCE}=" {'print $2'}  |  awk -F "," {'print $1'} )
	local sequence=$( printf %04d  $( expr $last_sequence + 1 ) )	
	
	myEcho 1 debug S "Incluindo na lista de desinstalacao: $operation $targetPath"
	# montando a entrada do registro
	local line="{SEQUENCE}=$sequence,{OPERATION}=$operation,{SOURCE}=$sourcePath,{TARGET}=$targetPath,{BACKUP}=$backupPath,"
	echo $line  |  cleanPath  >> "$GLO_UNINSTALL_FILE"
	return $?
}


# ######################################################################
# ADICIONA UMA ENTRADA DE ARQUIVO/DIRETORIO NA LISTA DE CONTROLE
addToPreprocessingFile() {
	# $1 - operacao (copy, remove)
	# $2 - origem path
	# $3 - destino path
	# $4 - backup path
	
	local operation=$1
	local sourcePath=$2
	local targetPath=$3
	#local backupPath=$4
	local myFile=preprocessingFile.list
	
	if [ ! -f "$myFile" ]; then
		myEcho 0 warn S "Arquivo de pre-processamento ($myFile) nao existe. Criando novo..."
		touch "$myFile"
	fi
	
	# obtem o ultimo sequence
	# TODO - otimizar este comando para utilizar apenas 1 awk
	local last_sequence=$( awk 'END{print}' $myFile   |  awk -F "{SEQUENCE}=" {'print $2'}  |  awk -F "," {'print $1'} )
	local sequence=$( printf %04d  $( expr $last_sequence + 1 ) )	
	
	myEcho 0 debug S "Incluindo na lista de pre-processamento: $operation $targetPath"
	# montando a entrada do registro
	local line="{SEQUENCE}=$sequence,{OPERATION}=$operation,{SOURCE}=$sourcePath,{TARGET}=$targetPath,"
	echo $line  |  cleanPath  >> "$myFile"
	return $?
}




# ######################################################################
# LOCALIZA A TAG HOST NO ARQUIVO DE HOSTS E RETORNA OS VALORES DE HOST NAMES ASSOCIADOS
# $1 - tag de host desejada
# $2 - string com a relacao completa de hosts (cat de arquivo)
# retorno: string de host names
getHostNamesParsed() {
	local hostTag="$1"
	local hostsFile="$2"
	# ATENCAO: nao imprimir nada na saida padrao. A funcao chamadora espera receber somente um print com os hostnames

	[ $# -ne 2 ] && return 1   #   retorna erro se numero parametros errado
	#[ "$hostTag" == "" ] && return 0
	

	local getTag=$( echo "$hostTag"  |  grep '{.*}' ) # armazena so se for tag
	#myEcho  0 debug S " "  >&2
	#myEcho  0 debug S "getTag=$getTag"  >&2
	
	# se for um hostname simples, retorna o hostname e sai da funcao
	if [ "$getTag" == "" ]; then
		echo -n "$hostTag "
		return 0
	fi
	
	local hostTagValue=$( echo "$hostsFile"  |  grep "^$hostTag" |  cut -d'=' -f2 )       # obtem o valor da tag
	local hostList=$( echo "$hostTagValue"   |  sed  's|{[^}]*}|\n&\n|g' ) # lista de possiveis sub-tags
	#myEcho  0 debug S "hostTag=$hostTag"  >&2
	#myEcho  0 debug S "hostTagValue=$hostTagValue"  >&2
	#myEcho  0 debug S "hostList=$hostList"  >&2
	
	# se ha sub-tags
	if [ "$hostList" != "" ]; then
		
		# itera para cada uma das sub-tags
		while read hostItem; do
			# faz o parsing novamente  (recursivo)
			#myEcho  0 debug S "getHostNamesParsed  $hostItem  $hostsFile"  >&2
			getHostNamesParsed  "$hostItem"  "$hostsFile"
		done <<< "$hostList"
	else
		# obtem o valor da tag
		#echo -n "$hostTagValue "   # print delimitado por espaco
		echo -n "$hostTagValue "   # print delimitado por espaco
	fi
}




# ######################################################################
# RETORNA O VALOR DE UM CAMPO DO ARQUIVO DE DESINSTALACAO
getUninstallField() {
	# entrada: via stdin - uma linha do arquivo
	# saida:  string na stdout
	
	local field=$( echo "$1"  |  tr '[a-z]' '[A-Z]' )
	local value=$( awk -F "{$field}=" {'print $2'}  |  awk -F "," {'print $1'} )
	if [[ "$value" != "" ]]; then
		echo "$value"
	fi
}



# ######################################################################
# baseado no etapa3Install
startUninstallSO() {
	local result=$GLO_SUCCESS
	myEcho 0 info t1 "[desinstalacao] Executando etapa Desinstalacao..."
	
	# ***** validacao da existencia do $GLO_UNINSTALL_FILE
	if [ ! -e "$GLO_UNINSTALL_FILE" ]; then
		myEcho 0 error S "Impossivel continuar desinstalacao automatica. O arquivo '$GLO_UNINSTALL_FILE' nao existe. Caso exista a pasta de backup, restaure manualmente os arquivos."
		myEcho 0 info S "Desinstalacao abortada"

		exit 1
	fi
	

	local tmpfile=$( getTmpFilename "etapa5Uninstall" )
	#local msg="Encontrado argumento invalido: "

	#local varListTreeCommands=$(</dev/stdin)
	local varListTargetPath
	local oldsourceCommandLine
	
	# === iterando pela lista de comandos origem
	# CUIDADO se colocar "$varListTreeCommands" entre parenteses da problema!
	while read line; do
		echo

		local sequence=$(   echo "$line"  |  getUninstallField "SEQUENCE" )
		local command=$(    echo "$line"  |  getUninstallField "OPERATION" )  #  TODO - verificar se chama isso de operation ou command
		local sourcePath=$( echo "$line"  |  getUninstallField "SOURCE" )
		local targetPath=$( echo "$line"  |  getUninstallField "TARGET" )
		local backupPath=$( echo "$line"  |  getUninstallField "BACKUP" )
		
		local sourceCommandLine="$sourcePath"		
		if [ "$sourceCommandLine" != "$oldsourceCommandLine" ]; then
			myEcho 1 info S "Lendo $sequence Origem $sourceCommandLine"
			oldsourceCommandLine=$sourceCommandLine
		fi
				
		#varListTargetPath=$( echo "$sourceCommandLine"  |  listParsed  |  listTargetPath )
		varListTargetPath="$targetPath"
				
		# === iterando pela lista de comandos destino (pode ser 1 -> 1  ou  1 -> N)
		# CUIDADO se colocar "$varListTargetPath" entre parenteses da problema!
		for targetPath in $varListTargetPath; do
			
			# verifica se tem tags cujo parsing nao foi aplicado
			#invalidTagTargetPath=$( echo "$targetPath"  |  grep "{.*}" )
			#if [[ "$invalidTagTargetPath" != "" ]]; then
			#	echo "[error] $invalidTagTargetPath - tags invalidas nos argumentos"
			#fi
			
			# verifica se a entrada esta dentro do escopo de execucao deste host
			#local varExecutionScope=$( echo $sourceCommandLine  |  listExecutionScope )
			local varExecutionScope="sim todos no arquivo estao no escopo de execucao deste host"
			if [[ "$varExecutionScope" != "" ]]; then
					# obtem o tipo de comando
					# TODO - no momento estou considerando apenas 1 comando
					#local command="$( echo "$sourceCommandLine"  |  getListCommand )"

					#myEcho 1 debug S "sequence=$sequence"  >&2
					#myEcho 1 debug S "command=$command"  >&2
					#myEcho 1 debug S "sourcePath=$sourcePath"  >&2
					#myEcho 1 debug S "targetPath=$targetPath"  >&2
					#myEcho 1 debug S "backupPath=$backupPath"  >&2
					
					
					# OBS Na etapa de instalacao essa operacao chama-se copy ou modify
					if [[ "$command" == "remove" ]]; then
						
						# verifica se nao existe no Destino
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								myEcho 1 warn S "$targetPath - arquivo nao existe no Destino"  >&2
								
							# se for diretorio
							elif [ -d "$sourceCommandLine" ]; then
								myEcho 1 warn S "$targetPath - diretorio nao existe no Destino"  >&2
							
							else
								myEcho 1 error S "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
						else
							myEcho 2 info S  "Excluindo $targetPath"
							myEcho 2 debug S  "rm -rf  $targetPath"
							
							rm -rf  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
						fi

					# OBS Na etapa de instalacao essa operacao chama-se remove (remove_file, remove_dir, remove_all)
					elif [[ "$command" == "copy" ]]; then
					
						# verifica se nao existe no Destino
						if [ ! -e "$targetPath" ]; then
							# se for arquivo
							if [ -f "$sourceCommandLine" ]; then
								myEcho 2 debug S  "$targetPath - arquivo nao existe no Destino. Criando..."
								myEcho 2 debug S  "mkdir -p $( dirname "$targetPath")"
								
								mkdir -p "$( dirname "$targetPath")"  # compativel com nomes com espacos
								
							# se for diretorio
							elif [ -d "$sourceCommandLine" ]; then
								#myEcho 2 warn S  "$targetPath - diretorio nao existe no Destino. Criando..."
								#myEcho 2 debug S  "mkdir -p $targetPath"
								
								mkdir -p "$targetPath"
								#mkdir -p "$( dirname "$targetPath")"  # compativel com nomes com espacos								

							else
								myEcho 2 error S  "Nao e um arquivo regular!"
								result=$GLO_ERROR
							fi
						else
							myEcho 2 debug S  "$targetPath - destino existente"
							
							targetPath=$( dirname "$targetPath" )
						fi
						
						myEcho 2 info S  "Copiando $backupPath  --->  $targetPath"
						myEcho 2 debug S  "cp -rfp  $backupPath  $targetPath"
						
						cp -rfp  "$backupPath"  "$targetPath"   ||   { GLO_STATUSCMD=$?; result=$GLO_ERROR; exitStatusHandler "break 2"; }
		
					else
						myEcho 2 error S "$command - comando invalido!"
						result=$GLO_ERROR
					fi
			else
				myEcho 2 debug S "Desinstalacao pulada. Instrucao para outro host"
			fi
		done
		
		# mostra erro caso esteja faltando argumentos pos-comando
		if [ "$varListTargetPath" == "" ]; then
			myEcho 2 error S "$sourceCommandLine  - comando sem argumentos"
			result=$GLO_ERROR
		fi
	done < "$GLO_UNINSTALL_FILE"
	
	return $result
}


# ######################################################################
# OBTEM O VALOR DA VARIAVEL SYSTEM_FILE DO AMBIENTE OU ENTAO O SYSTEM_FILE EMULADO
# retorno: string
getSYSTEM_FILE() {
	local var_SYSTEM_FILE=$SYSTEM_PATH/environment.cfg
	
	if [ "$GLO_EMULATE_SYSTEM_PATH" != "" ]; then
	
		#if [[ ($GLO_INSTALL_OPERATION != $GLO_INSTALL_OPERATION_VALIDATE) ]]; then 
			var_SYSTEM_FILE=$GLO_EMULATE_SYSTEM_PATH/environment.cfg
		#fi
	fi
	
	echo $var_SYSTEM_FILE
}