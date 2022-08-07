# Remember The Bread - Terraform

Este repositorio contiene la definición de la arquitectura de la webapp **Remember The Bread** en formato Terraform. 

## Cómo levantar la arquitectura

Una vez clonado este repositorio, debemos disponer de las credenciales de AWS para que Terraform pueda hacer uso de ellas. En la [documentación oficial](https://www.terraform.io/docs/providers/aws/index.html) se detalla cómo puede hacerse.

El siguiente paso es crear localmente el key pair de las instancias de EC2. 
```bash
# Usamos como ruta ./key
$ ssh-keygen -t rsa -b 4096 -C "key"
$ ssh-keygen -f ./key -p -m PEM
```

Es importante crear el key pair en el directorio raíz del repositorio, además de respetar el nombre indicado. De hacerlo en otro directorio o con otro nombre, será necesario actualizar la configuración del key pair en `variables.tf`.

Ahora sí, tenemos todo listo para levantar la arquitectura. Ejecutamos estos comandos:

```bash
# Inicializamos el proyecto
$ terraform init

# Construimos la arquitectura
$ terraform apply
```

Una vez haya terminado el apply, Terraform nos informa del DNS del balanceador, que es a donde debemos navegar para ver que Remember The Bread está funcionando. 
