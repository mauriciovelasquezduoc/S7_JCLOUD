# Paso a paso: Docker y Spring Boot (scripts llegar y copiar)

JVY0101 - Java: Diseño y Construcción de Soluciones Nativas en Nube
Guía 2.3.2 - Experiencia de Aprendizaje EA2 - Indicador IL2.3

> **Antes de empezar:** ajusta los nombres de contenedor a los tuyos. En la guía
> original el texto usa `mysql-ejemplo` y las capturas usan `mysql-gry2204`.
> En este documento se usa `mysql-ejemplo` de forma consistente.
> Si tu contenedor se llama distinto, reemplaza el nombre en cada comando.

> **Entorno:** todos los comandos están pensados para ejecutarse desde la
> **consola de Windows** (CMD o PowerShell), **sin IDE**. La aplicación Java se
> compila y se ejecuta con Maven desde la terminal.

Variables usadas en todo el documento:

| Variable           | Valor por defecto   |
| ------------------ | ------------------- |
| `MYSQL_CONTAINER`  | `mysql-ejemplo`     |
| `BACKEND_IMAGE`    | `backend`           |
| `BACKEND_CONTAINER`| `backend-app`       |
| `NETWORK`          | `backend_network`   |
| Puerto MySQL       | `3306`              |
| Puerto Backend     | `8180`              |

---

## Paso 1. Instalar Docker Desktop

Descargar desde el sitio oficial según el sistema operativo:

https://www.docker.com/products/docker-desktop/

- Inicializar el ejecutable y seguir el asistente.
- Aceptar los términos del software.
- Ingresar con una cuenta o presionar **Skip**.
- Verificar que la interfaz de Docker Desktop se visualice correctamente.

> **Requisito:** el equipo debe tener habilitada la virtualización en la BIOS
> (el procedimiento depende de cada fabricante).

Verificar la instalación desde una terminal:

```bash
docker --version
docker info
```

---

## Paso 2. Instalar Postman

Descargar desde el sitio oficial según el sistema operativo:

https://www.postman.com/

- Seguir las instrucciones de instalación.
- Loguearse con una cuenta (es requerido para que el software funcione).
- Verificar que se muestre la pantalla principal de Postman.

---

## Paso 3. Levantar MySQL en Docker

Abrir una terminal dentro de la carpeta `Docker y comandos` (que contiene el
`Dockerfile` y `create.sql`) y ejecutar:

```bash
# Construir la imagen de MySQL (el PUNTO final es obligatorio)
docker build -t mysql-ejemplo .

# Levantar el contenedor
docker run -d -p 3306:3306 --name mysql-ejemplo mysql-ejemplo
```

Verificar que el contenedor quedó arriba:

```bash
docker ps
```

Entrar al contenedor y conectarse a MySQL:

```bash
docker exec -it mysql-ejemplo mysql -p
```

> Al ejecutar `mysql -p` se solicita la contraseña. Si todo está correcto,
> se accede a la consola de MySQL.

---

## Paso 4. Ejecutar el código base (Spring Boot)

El código debe apuntar al mismo puerto del microservicio de MySQL (`3306`).
Revisar el archivo `src/main/resources/application.properties`:

```properties
spring.application.name=backend

spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.MySQL8Dialect
spring.datasource.url=jdbc:mysql://localhost:3306/mydatabase
spring.datasource.username=myuser
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
logging.level.org.springframework.web=trace
logging.level.org.hibernate=trace
logging.level.com=TRACE
logging.file.name=backend.log
server.port=8180
```

Iniciar la aplicación **desde la consola de Windows** (sin IDE).

Requisitos previos:

- Tener instalado **JDK 17** y disponible en el `PATH`:

```bat
java -version
javac -version
```

- El proyecto incluye el **Maven Wrapper** (`mvnw.cmd`), por lo que **no es
  necesario instalar Maven**. Solo abre la consola en la carpeta raíz del código
  (donde está `mvnw.cmd`) y ejecuta:

```bat
REM CMD (Símbolo del sistema)
cd C:\ruta\al\codigoBase
mvnw.cmd spring-boot:run
```

```powershell
# PowerShell
cd C:\ruta\al\codigoBase
.\mvnw.cmd spring-boot:run
```

> Al iniciar, Maven descarga las dependencias, compila y levanta Tomcat en el
> puerto `8180`. En los logs verás algo como
> `Tomcat started on port 8180 (http)`. Al iniciar la aplicación se crean las
> tablas de las entidades.
>
> Para detener la aplicación presiona `Ctrl + C` en la misma consola.

---

## Paso 5. Crear un usuario en la base de datos

En la consola de MySQL del contenedor (`mysql -p`):

```sql
-- Seleccionar la base de datos
use mydatabase;

-- Ver la estructura de la tabla para armar el insert
desc user;

-- Crear el usuario de prueba
insert into user values(1,'test@mail.cl','1234','test');
```

---

## Paso 6. Probar el login y el endpoint con Postman

**6.1 Obtener el token (POST):**

```text
curl -X POST "http://localhost:8180/login?user=test&encryptedPass=1234"
```

Copiar el token generado **sin** la palabra `Bearer`.

**6.2 Consumir un endpoint protegido:**

```text
Endpoint:      http://localhost:8180/patient/register
Authorization: Bearer Token
Token:         <token generado por el endpoint Login>
```

**6.2.1 Importar el Login en Postman con cURL**

En Postman: **Import** → pestaña **Raw text** → pega el siguiente cURL → **Import**.
Guárdalo en tu colección con el nombre `Login`.

```bash
curl --location --request POST 'http://localhost:8180/login?user=test&encryptedPass=1234'
```

**6.2.2 Crear un Pre-request Script para obtener el token automáticamente**

1. Importa la petición del endpoint protegido con el cURL de **6.2.4** (o créala a
   mano como `GET http://localhost:8180/patient/register`).
2. Abre la petición y ve a la pestaña **Scripts** → **Pre-request**.
3. Pega el siguiente script (hace el POST al login y guarda el token en la
   variable de colección `token`, sin la palabra `Bearer`):

```javascript
const loginUrl = "http://localhost:8180/login?user=test&encryptedPass=1234";

pm.sendRequest({ url: loginUrl, method: "POST" }, function (err, res) {
    if (err) {
        console.error("Error al obtener el token:", err);
        return;
    }
    const token = res.text().replace(/^Bearer\s+/i, "").trim();
    pm.collectionVariables.set("token", token);
    console.log("Token obtenido:", token);
});
```

4. Guarda la petición. Cada vez que la envíes, el token se obtendrá solo.

**6.2.3 Usar el token en la petición**

En la pestaña **Authorization** de la petición:

- **Type:** `Bearer Token`
- **Token:** `{{token}}`

**6.2.4 cURL del endpoint protegido (para importar)**

Postman: **Import** → **Raw text** → pega este cURL:

```bash
curl --location --request GET 'http://localhost:8180/patient/register' \
  --header 'Authorization: Bearer {{token}}'
```

---

## Paso 7. Generar y ejecutar el artefacto `.jar` con Maven (consola Windows)

Abrir la consola en la carpeta raíz del código (donde está `mvnw.cmd`).

Primero, eliminar la carpeta `target`:

```bat
REM CMD
rmdir /s /q target
```

```powershell
# PowerShell
Remove-Item -Recurse -Force target
```

Antes de empaquetar, ajustar `application.properties` para que el backend apunte
al contenedor de MySQL (nombre del contenedor como host):

```properties
spring.datasource.url=jdbc:mysql://mysql-ejemplo:3306/mydatabase
```

Compilar y empaquetar con el Maven Wrapper:

```bat
REM CMD
mvnw.cmd clean package
```

```powershell
# PowerShell
.\mvnw.cmd clean package
```

> Si tienes Maven instalado globalmente también puedes usar `mvn clean package`.
> Esperar el mensaje **BUILD SUCCESS**.

El JAR se genera en `target\`. Para ejecutarlo **desde la consola** (sin IDE):

```bat
java -jar target\backend-0.0.1-SNAPSHOT.jar
```

> El nombre del JAR depende del `artifactId` y la versión del `pom.xml`
> (`backend` + `0.0.1-SNAPSHOT`). Si no coincide, revisa el contenido de
> `target\` con `dir target`.
>
> Para detener la aplicación presiona `Ctrl + C`.

### Referencia de comandos Maven (Windows)

| Comando                        | Función                                        |
| ------------------------------ | ---------------------------------------------- |
| `mvnw.cmd clean`               | Limpia la carpeta `target`                     |
| `mvnw.cmd compile`             | Compila el código fuente                       |
| `mvnw.cmd test`                | Ejecuta las pruebas unitarias                  |
| `mvnw.cmd package`             | Genera el `.jar` en `target\`                  |
| `mvnw.cmd spring-boot:run`     | Compila y ejecuta la app sin generar el JAR    |
| `mvnw.cmd clean package`       | Limpia y genera el `.jar` en un solo paso      |

---

## Paso 8. Crear el microservicio (imagen) del backend

Desde la raíz del código, usando el `DockerfileJar`:

```bash
docker build -t backend -f DockerfileJar .
```

---

## Paso 9. Crear la red y conectar los microservicios

Para que la API y MySQL se reconozcan entre sí:

```bash
# Levantar el contenedor del backend
docker run -d -p 8180:8180 --name backend-app backend

# Crear la red
docker network create backend_network

# Conectar ambos contenedores a la red
docker network connect backend_network mysql-ejemplo
docker network connect backend_network backend-app
```

> **Nota:** en la guía original este paso aparece con `mysql-ejemplo-2025` y en
> las capturas con `mysql-gry2204`. Usa aquí el nombre real de tu contenedor de
> MySQL creado en el Paso 3.

---

## Paso 10. Verificar que todo esté operativo

El backend puede quedar detenido porque al hacer `docker run` los microservicios
no estaban en la misma red. En ese caso, iniciar `backend-app` desde Docker Desktop
o con:

```bash
docker start backend-app
```

Comprobar el estado de ambos microservicios:

```bash
docker ps
```

Deberían verse operativos: el contenedor de MySQL y `backend-app`.

---

## Resumen de comandos (todo en orden, consola Windows)

```bat
REM 3. MySQL (nombre de imagen en minúscula, nombre de contenedor libre)
docker build -t mysql-ejemplo .
docker run -d -p 3306:3306 --name mysql-ejemplo mysql-ejemplo
docker exec -it mysql-ejemplo mysql -p

REM 5. Usuario en la BD (dentro de la consola MySQL)
REM   use mydatabase;
REM   desc user;
REM   insert into user values(1,'test@mail.cl','1234','test');

REM 4/7. Compilar y ejecutar la app con Maven (desde la raíz del código)
mvnw.cmd clean package
java -jar target\backend-0.0.1-SNAPSHOT.jar
REM   Alternativa sin generar JAR:
REM   mvnw.cmd spring-boot:run

REM 8. Imagen del backend
docker build -t backend -f DockerfileJar .

REM 9. Red y conexión
docker run -d -p 8180:8180 --name backend-app backend
docker network create backend_network
docker network connect backend_network mysql-ejemplo
docker network connect backend_network backend-app

REM 10. Verificación
docker ps
```

## Limpieza (opcional)

```bat
REM Detener y eliminar contenedores
docker stop backend-app mysql-ejemplo
docker rm backend-app mysql-ejemplo

REM Eliminar la red
docker network rm backend_network

REM Eliminar imágenes
docker rmi backend mysql-ejemplo
```
