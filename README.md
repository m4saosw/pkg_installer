# pkg_installer
Custom package installer - devops tools

Uma ferramenta de instalação customizável de pacotes de aplicações para hosts rodando em ambientes Linux.
Provê uma infraestrutura basica de operações comuns para serem utilizadas em sustentação de aplicações, como manipulação de arquivos e diretórios (cópia, alteração de configurações, exclusão de arquivos e diretórios).


## Características
- Instalação e desinstalação para arquivos e diretórios no sistema operacional
- Instalação e desinstalação para bancos de dados por meio de scripts (DDL e SQL)
- Logs de acompanhamento operacional
- Capacidade de instalação multi-ambiente, isto é, com diferenciação para hosts de desenvolvimento, integração, homologação, produção
- Orientado a templates para maior produtividade.
- Operações de manipulação de arquivos e diretórios baseadas em tags intuitivas


## Tecnologias
    Shellscript Bash


## Execução
```
$ install.sh  <tipo de operacao>
```
**Parâmetros:**
1. tipo de operacao  - start ou validate


**Exemplos:**
Executa em modo de varredura interna buscando configurações incorretas. Esta execução é recomendada durante a fase de desenvolvimento do pacote.
```
$ install.sh  validate
```

Executa a instalação
```
$ install.sh  start
```


## Configurações
***hosts.properties***
Permite a definição dos hosts e categorias de ambientes.


***installer.properties***
Permite a definição de hosts mock para teste de instalação.