# pkg_installer
Custom packages installer - a devops tool

A customizable package installation tool, entirelly made by shellscript, running by command line, for enterprise application running in a Linux environment.
Provides a high level infrastructure for common file and directory manipulation operations, assisting with maintanance tasks of enterprise applications.

## Features
- Install and uninstall files, directories and also database scripts to maintain a database (scripts DML or DDL);
- Logging output;
- Multi-environment concept: the same package can be installed in any host category such as: development, integration and production; and the tool manages which commands are applied to each of them;
- Structure oriented to template, for better productivity;
- Easy tag-based sintax for the most common commands;


## Technology
    Shellscript Bash


## How to use
```
$ install.sh  <type>
```
**Parameters:**
start OR validate


**Examples:**

1) To check for wrong settings. This option is recommended for the development phase.
```
$ install.sh  validate
```

2) To perform the installation
```
$ install.sh  start
```

**Example of internal package structure**

In this example, the package's structure directory does some operations on the target hosts:
- edits the content of a file on the ENGINE_CLI host;
- removes a file on the ENGINE_CLI host;
- copy a new file to a specific path in ENGINE_LOCAL host;
- removes all files from a directory;
- removes a entire directory at the destination;

```
files/so/commands/ambiente/{ENGINE_CLI}/{modify}/umdiretoriodamaquina/umsubdiretorio/umarquivoaseralterado.txt
files/so/commands/ambiente/{ENGINE_CLI}/{remove_file}/umarquivoaexcluir.txt
files/so/commands/ambiente/{ENGINE_LOCAL}/{copy}/{product_path}/engine/instance/1/configuration/um novo arquivo.txt
files/so/commands/ambiente/{ENGINE_LOCAL}/{remove_all}/umdiretoriocujosarquivosseraoexcluidosinternamente
files/so/commands/ambiente/{ENGINE_LOCAL}/{remove_dir}/umdiretorioaexcluirporcompleto
```


## Configuration
***hosts.properties***
Host configuration using tags that identify hosts categories.


***installer.properties***
Other configurations, such as like simulation to support the test installation during the development phase.


## Considerations
The current version does not support connecting to multiple hosts. It is necessary to run the script on each of the desirables hosts.
