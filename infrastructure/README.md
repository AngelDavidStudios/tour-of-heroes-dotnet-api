# 🏗️ Terraform Infrastructure

Este directorio contiene la infraestructura como código para desplegar la API Tour of Heroes en Azure.

## 🎯 Recursos Azure

La infraestructura despliega los siguientes recursos en Azure:

| Recurso | Descripción | Condicional |
|---------|-------------|-------------|
| Resource Group | Grupo de recursos `Tour-Of-Heroes` | Siempre |
| App Service Plan | Plan S1 para Windows | Siempre |
| Windows Web App | App Service con .NET 9.0 | Siempre |
| Web App Slot | Slot de staging | Siempre |
| SQL Server | Azure SQL Server v12.0 | Si `database_provider = "SqlServer"` |
| SQL Database | Base de datos `heroes` (SKU Basic) | Si `database_provider = "SqlServer"` |
| PostgreSQL Flexible Server | PostgreSQL v16 (B_Standard_B1ms) | Si `database_provider = "PostgreSQL"` |
| PostgreSQL Database | Base de datos `heroes` | Si `database_provider = "PostgreSQL"` |
| Firewall Rules | Permitir servicios Azure | Según el proveedor |

## 📋 Variables

### Requeridas

| Variable | Descripción | Tipo |
|----------|-------------|------|
| `db_user` | Usuario administrador de la base de datos | `string` |
| `db_password` | Contraseña del administrador | `string` (sensitive) |

### Opcionales

| Variable | Descripción | Default | Valores |
|----------|-------------|---------|---------|
| `database_provider` | Proveedor de base de datos | `"SqlServer"` | `"SqlServer"`, `"PostgreSQL"` |
| `postgresql_admin_password` | Contraseña específica para PostgreSQL | `null` (usa `db_password`) | `string` |
| `project_name` | Nombre del proyecto | `"tour-of-heroes"` | `string` |
| `environment` | Nombre del entorno | `"prod"` | `string` |

## 🚀 Uso

### 1. Inicializar Terraform

```bash
cd infrastructure
terraform init
```

### 2. Configurar variables

Edita `terraform.tfvars` o usa variables de entorno:

**Para SQL Server (default):**
```hcl
db_user           = "mradministrator"
db_password       = "YourStrong@Password1"
database_provider = "SqlServer"
```

**Para PostgreSQL:**
```hcl
db_user                   = "psqladmin"
db_password               = "YourStrong@Password1"
database_provider         = "PostgreSQL"
postgresql_admin_password = "YourStrong@Password1"
```

### 3. Ver el plan de despliegue

```bash
# Con SQL Server
terraform plan

# Con PostgreSQL
terraform plan -var="database_provider=PostgreSQL"
```

### 4. Aplicar la infraestructura

```bash
terraform apply
```

## 🔄 Cambiar de proveedor de base de datos

Para cambiar de SQL Server a PostgreSQL o viceversa:

1. Actualiza la variable `database_provider` en `terraform.tfvars`
2. Ejecuta `terraform plan` para ver los cambios
3. Ejecuta `terraform apply` para aplicar los cambios

⚠️ **ADVERTENCIA**: Cambiar el proveedor destruirá la base de datos actual y creará una nueva. Asegúrate de hacer backup de tus datos antes.

## 💰 Costes estimados (por mes)

| Recurso | SKU/Tier | Coste aproximado |
|---------|----------|------------------|
| App Service Plan | S1 | ~$70 USD |
| SQL Database | Basic | ~$5 USD |
| PostgreSQL Flexible Server | B_Standard_B1ms | ~$15 USD |

Total mensual:
- Con SQL Server: ~$75 USD
- Con PostgreSQL: ~$85 USD

## 🔧 Configuración avanzada

### Backend de estado remoto

El proyecto está configurado para usar Azure Storage como backend:

```hcl
terraform {
  backend "azurerm" {
    key = "tour-of-heroes-tf-state"
  }
}
```

Configura las siguientes variables de entorno antes de `terraform init`:

```bash
export ARM_RESOURCE_GROUP_NAME="terraform-state-rg"
export ARM_STORAGE_ACCOUNT_NAME="tfstate"
export ARM_CONTAINER_NAME="tfstate"
```

### Tags comunes

Todos los recursos se etiquetan automáticamente:

```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  ManagedBy   = "Terraform"
}
```

## 🔐 Seguridad

- Las contraseñas se marcan como `sensitive = true`
- Las reglas de firewall permiten servicios Azure (0.0.0.0)
- SQL Server y PostgreSQL usan SSL/TLS
- Las connection strings se configuran como Connection Strings en App Service

## 📝 Outputs

Después de aplicar, Terraform puede mostrar:
- URL del App Service
- Nombre del servidor de base de datos
- Connection strings (sin contraseñas)

Para añadir outputs, crea un archivo `outputs.tf`.

---

*This infrastructure was created with GitHub Copilot 🤖*
