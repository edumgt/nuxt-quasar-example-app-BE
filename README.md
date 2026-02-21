# Springboot rest api

## 로컬 실행 스크립트 (MySQL Docker + SQL 초기화 + Spring Boot)

아래 스크립트 하나로 다음 순서를 자동 수행합니다.
1. MySQL Docker 컨테이너 생성/시작
2. `scripts/init.sql` 실행 (DB/테이블 생성)
3. `./gradlew bootRun` 실행

```bash
./scripts/start-mysql-and-boot.sh
```

필요 시 환경변수로 값을 덮어쓸 수 있습니다.

```bash
MYSQL_CONTAINER_NAME=spring-starter-mysql \
MYSQL_IMAGE=mysql:8.4 \
MYSQL_PORT=3306 \
MYSQL_ROOT_PASSWORD=strong_pwd \
./scripts/start-mysql-and-boot.sh
```

## 사전에 WSL(WSL2) 설치/관리 + 여러 리눅스 배포판 설치 + Docker Desktop(WSL2) 공유 정리

> 기준: Windows 10/11에서 **WSL2**를 사용하는 일반적인 케이스  
> PowerShell(관리자 권한)에서 실행해야 하는 명령은 ✅로 표시했습니다.

---
```
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true

[user]
default=root

[automount]
enabled=true
options = "metadata,umask=22,fmask=11"
mountFsTab=true
EOF
```

---

## 0) 빠른 결론 (Docker Desktop + WSL2)
- **Docker Desktop + WSL2 백엔드 + WSL Integration 사용**이면  
  → Windows와 WSL Linux는 **같은 Docker 엔진을 공유**하므로 **이미지/컨테이너가 공유**됩니다.
- WSL Ubuntu 안에 **docker-ce를 별도로 설치**하고 그 안에서 `dockerd`를 따로 띄우면  
  → Docker Desktop 엔진과 **분리**되어 **공유되지 않습니다.**

---

## 1) WSL/WSL2 설치 (가장 쉬운 방법)
### 1-1) WSL 설치/기본 세팅 (권장)
✅ **PowerShell(관리자)**:
```powershell
wsl --install
```

- 기본으로 Ubuntu가 함께 설치되는 경우가 많습니다.
- 설치 후 재부팅이 필요할 수 있어요.

### 1-2) WSL 상태/버전 확인
```powershell
wsl --status
```

### 1-3) WSL 업데이트 (커널 업데이트)
✅ PowerShell(관리자):
```powershell
wsl --update
```

### 1-4) 기본 WSL 버전을 WSL2로 지정
```powershell
wsl --set-default-version 2
```

---

## 2) 설치 가능한 리눅스 목록 조회 & 여러 배포판 설치
### 2-1) 설치 가능한 배포판(온라인) 목록 보기
```powershell
wsl --list --online
# 또는 축약
wsl -l -o
```

### 2-2) 원하는 배포판 설치
예: Ubuntu / Debian / Kali / openSUSE 등
```powershell
wsl --install -d Ubuntu
wsl --install -d Debian
wsl --install -d kali-linux
```

> 배포판 이름은 `wsl -l -o` 결과에 표시된 이름을 그대로 쓰면 됩니다.

---

## 3) 현재 설치된 WSL 배포판 목록 보기 (설치 목록)
### 3-1) 설치된 배포판 목록
```powershell
wsl --list
# 축약
wsl -l
```

### 3-2) 설치된 배포판 + WSL 버전(1/2)까지 보기 (추천)
```powershell
wsl --list --verbose
# 축약
wsl -l -v
```

---

## 4) 실행/접속/기본 배포판 관리
### 4-1) 특정 배포판 실행(접속)
```powershell
wsl -d Ubuntu
wsl -d Debian
```

### 4-2) 특정 배포판에서 특정 명령만 실행
```powershell
wsl -d Ubuntu -- uname -a
wsl -d Debian -- cat /etc/os-release
```

### 4-3) 기본 배포판 지정
```powershell
wsl --set-default Ubuntu
```

### 4-4) 실행 중인 배포판 종료
- 전체 WSL 종료:
```powershell
wsl --shutdown
```

- 특정 배포판만 종료:
```powershell
wsl --terminate Ubuntu
```

---

## 5) WSL1 ↔ WSL2 변환/설정
### 5-1) 특정 배포판을 WSL2로 변경
```powershell
wsl --set-version Ubuntu 2
```

### 5-2) 특정 배포판을 WSL1로 변경(특수 목적)
```powershell
wsl --set-version Ubuntu 1
```

---

## 6) 배포판(리눅스) 삭제/백업/복원
### 6-1) 배포판 완전 삭제(주의!)
```powershell
wsl --unregister Ubuntu
```
> ⚠️ 해당 배포판의 파일시스템/데이터가 모두 삭제됩니다.

### 6-2) 배포판 백업(export)
```powershell
wsl --export Ubuntu C:\backup\ubuntu.tar
```

### 6-3) 배포판 복원(import) - 새 이름으로 가져오기
```powershell
wsl --import UbuntuRestored C:\WSL\UbuntuRestored C:\backup\ubuntu.tar --version 2
```

---

## 7) Windows ↔ WSL 파일 경로/접근
### 7-1) WSL에서 Windows 드라이브 접근
- C드라이브:
```bash
cd /mnt/c
```

### 7-2) Windows 탐색기에서 WSL 파일 보기
- 탐색기 주소창에 입력:
```text
\\wsl$\Ubuntu
```

### 7-3) 현재 WSL 디렉터리를 Windows 탐색기로 열기
WSL(리눅스)에서:
```bash
explorer.exe .
```

---

## 8) 네트워크/포트 관련 빠른 팁
- WSL2는 내부적으로 가상 네트워크를 쓰므로 IP가 달라질 수 있어요.
- 보통은 `localhost` 포트 포워딩이 동작하지만, 방화벽/보안 설정에 따라 예외가 있을 수 있습니다.
- WSL에서 현재 IP 확인:
```bash
ip addr
```

---

## 9) 자주 쓰는 “운영” 명령 모음 (치트시트)
### 9-1) 현재 설치/실행 현황 빠르게 보기
```powershell
wsl -l -v
wsl --status
```

### 9-2) 특정 배포판에서 패키지 업데이트 (Ubuntu/Debian)
WSL(리눅스) 안에서:
```bash
sudo apt update
sudo apt upgrade -y
```

---

## 10) Docker Desktop + WSL2 “공유 엔진” 확인
### 10-1) WSL Ubuntu에서 Docker Desktop 엔진을 보는지 확인
WSL Ubuntu에서:
```bash
docker info | grep -E "Server Version|Operating System"
```

- Docker Desktop(WSL2) 관련 정보가 나오면 보통 **공유 엔진**입니다.

### 10-2) Windows에서도 같은지 확인
PowerShell에서:
```powershell
docker images
docker ps
```

---

## 11) 흔한 문제 2가지
### 11-1) “WSL이 설치는 됐는데 배포판이 없음”
- `wsl -l -o`로 목록 확인 후 `wsl --install -d <배포판명>` 실행

### 11-2) Docker 이미지가 공유가 안 되는 것 같음
- WSL Ubuntu에 `docker-ce`를 직접 설치해서 엔진을 따로 돌리고 있으면 공유가 안 됩니다.
- Docker Desktop 설정에서:
  - WSL2 백엔드 사용
  - WSL Integration에서 해당 배포판(예: Ubuntu) 체크
를 확인하세요.

---

## 12) (선택) 성능/리소스 튜닝 팁
WSL2 리소스 제한은 `C:\Users\<사용자>\.wslconfig`로 조정할 수 있습니다. (파일이 없으면 생성)

예시:
```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

적용:
```powershell
wsl --shutdown
```
후 다시 WSL 실행하면 적용됩니다.

---
---

### linux 의 java update
```
sudo apt install -y openjdk-21-jdk
```

### windows 에서 linux 로 폴더 복제 후 조치
```
ubuntu@DESKTOP-8FSFFJK:~/Docker_1$ file ./gradlew
./gradlew: POSIX shell script, Unicode text, UTF-8 text executable, with CRLF line terminators
ubuntu@DESKTOP-8FSFFJK:~/Docker_1$ head -n 1 ./gradlew | cat -A
#!/bin/sh^M$
ubuntu@DESKTOP-8FSFFJK:~/Docker_1$ sed -i 's/\r$//' ./gradlew
ubuntu@DESKTOP-8FSFFJK:~/Docker_1$ ./gradlew tasks
```
---
```
./gradlew build -x test
```


# Front end
- Nuxt js + Quasar [https://github.com/edumgt/nuxt-quasar-example-app]

```mermaid
flowchart TD
    subgraph Client
        A[Client/Browser]
    end

    subgraph Spring Boot Application
        subgraph Security Layer
            B[JWT Filter]
            C[PreAuthorize]
        end

        subgraph Application Layer
            D[Controller]
            E[Service Interface]
            F[Service Implementation]
        end

        subgraph Data Layer
            G[Repository]
            H[Entity]
        end
    end

    subgraph Database
        I[(Database)]
    end

    A -->|1. HTTP Request with JWT| B
    B -->|2. Validate JWT| C
    C -->|3. Check Authorization| D
    D -->|4. Call Service| E
    E -->|5. Implementation| F
    F -->|6. Data Access| G
    G -->|7. Map| H
    H <-->|8. Persist/Retrieve| I

    classDef client fill:#e6f3ff,stroke:#333,stroke-width:2px
    classDef security fill:#ffe6e6,stroke:#333,stroke-width:2px
    classDef application fill:#e6ffe6,stroke:#333,stroke-width:2px
    classDef data fill:#fff2e6,stroke:#333,stroke-width:2px
    classDef database fill:#f2e6ff,stroke:#333,stroke-width:2px

    class A client
    class B,C security
    class D,E,F application
    class G,H data
    class I database
```

Requirements
------------

Only supported on Java 1.8 and up, MySql 8 and up.

## Usage


## Database

Database file located at `my-app`/spring-data/files/spring_starter.sql and you can use following command for restore to your db.

```batch
$ mysql -uroot -p your_db_name < your_backup_file_path
```
example on windows
```batch
$ mysql -uroot -p your_db_name < E:\bak\db\spring_starter.sql
```
example on Ubuntu
```batch
$ mysql -uroot -p your_db_name < /var/tmp/spring_starter.sql
```

Config your database connection at `my-app`/src/main/resources/`application.yml` or `application-dev.yml`
```yml
  datasource:
    url: jdbc:mysql://${MYSQL_HOST:localhost}:3306/`your_db_name`?allowPublicKeyRetrieval=true&useSSL=false
    username: `db_username`
    password: `your_db_password`
```
---
## Getting started

[//]: # (**Project structure**)

[//]: # (![image]&#40;https://user-images.githubusercontent.com/33171470/116986615-32423a00-acf8-11eb-88f7-db2e44a77b12.png&#41;)


Open Terminal and run following command 

```batch
./gradlew bootRun
```

To test that it works, open a browser tab at http://localhost:8080/welcome

---
Build production jar and run following command jar location `/build/libs/`

```batch
./gradlew bootJar
```

Docker run 
```batch
docker-compose build
docker-compose up -d
```

## API Docs
OpenAI, Swagger UI form API doc path
```
/api-docs, /swagger-ui/index.html
```

Server run at port `8080` can config server port at /src/main/resources/`application.yml`  
```yml
server:
  port: 8080
```

Change profiles active for development mode
```yml
spring:
  profiles:
#    active: prod
    active: dev
```

Development mode properties config at /src/main/resources/`application-dev.yml`
```yml
app:
  url: http://YOUR_SERVER_IP or http://127.0.0.1
  port: 8080
  cdn-directory: D:/code/tutorial/spring-data/ #your spring-data directory path
```

Log4j path config at resources/`log4j2-dev.xml` and resources/`log4j2-prod.xml`
```xml
<Property name="APP_LOG_ROOT">D:/code/tutorial/spring-data/logs</Property>
```
Log4j path config at resources/`log4j2-dev.xml` and resources/`log4j2-prod.xml`
```xml
<Property name="APP_LOG_ROOT">/usr/spring-data/logs</Property>
```

## Login

```
METHOD : POST
URL : /api/auth/login
```

**Request Headers**

| Key                  | Value                            | Description   |
| -------------------- |----------------------------------| --------------|
| Content-Type         | application/json;charset=utf-8   |               |
| Accept-Language      | th                               |       th, en        |
| Accept-ApiClient     | default                          |               |

**Request Parameters**
```
Json root name : user
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| email         | String  ||
| password      | String ||
| loginForm     | Int    |Login From – 1 : web browser , 2 : iOS, 3 : Android|

```json
{
  "user": {
    "emailOrUsername" : "admin@mydomain.com",
    "password" : "P@ssw0rd",
    "loginForm" : 1
  }
}
```

**Response success example** :tada:
```json
{
  "userId": 1,
  "authenticationToken": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJmNGQxOGRlZi1hZTBjLTQ2MjItODE4OS1iNzExOTViNTkwNGYiLCJleHAiOjE3MzAxNjUwODYsImlhdCI6MTY5ODYyOTA4Nn0.hKun9E7D4rc-yEOA85Ex6rFYfWQww7ViOS9mpdIUn2Ql66JGCyxYf2vtqjbsQ-DSz8HB1lmVRSWtJ4XeBFkwCg",
  "refreshToken": "f4d18def-ae0c-4622-8189-b71195b5904f",
  "expiresAt": "2024-10-29T01:24:46.019+00:00"
}
```
**Response fail example** :imp:

```json
{
  "status": "UNAUTHORIZED",
  "message": "Error",
  "errors": [
    "Login failed please verify that your username and password are correct."
  ],
  "timestamp": "2021-05-04 17:19:32"
}
```
---
**The header for the endpoint requires login verification.**

| Key                  | Value                            | Description   |
| -------------------- |----------------------------------| --------------|
| Content-Type         | application/json;charset=utf-8   |               |
| Accept-Language      | th                               |       th, en        |
| Accept-ApiClient     | default                          |               |
| Authorization    |Bearer `YOUR_authenticationToken` ||

**Get current User**
```
METHOD : GET
URL : /api/user/currentUserData
```
**Response success example** :tada:

```json
{
  "id": 1,
  "email": "admin@mydomain.com",
  "username": "admin",
  "token": null,
  "fcmToken": null,
  "accessTokenId": null,
  "avatarFileId": null,
  "coverFileId": null,
  "avatar": {
    "image": "http://127.0.0.1:8080/cdn/images/default-men-avatar.png",
    "thumbnail": "http://127.0.0.1:8080/cdn/images/default-men-avatar.png"
  },
  "cover": null,
  "active": true,
  "selectedRoles": [
    1
  ],
  "defaultLocale": "th"
}
```
## Permission

### Retrieve data

```
METHOD : GET
URL : /api/permission?page={currentPage}&size={size}&sort={#sortField,#sortType}
EXAMPLE : /api/permission?page=0&size=2&sort=code,asc
```
**Request Parameter**

| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| page         | Int  ||
| size      | Int ||
| sort     | string,string    |example `createdDate,asc`|

**Response success example** :tada:
```json
{
  "dataList": [
    {
      "id": 2,
      "code": "api_client_add",
      "description": "api_client_list_add",
      "module": "AD"
    },
    {
      "id": 5,
      "code": "api_client_delete",
      "description": "api_client_delete",
      "module": "AD"
    }
  ],
  "totalPages": 10,
  "totalElements": 2,
  "last": false
}
```
### Create data

```
METHOD : POST
URL : /api/permission
```
**Request Parameter**
```
Json root name : permission
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| code         | String  ||
| description      | String ||
| module     | String    ||

**Request example**
```json
{
  "permission": {
    "code": "read_report",
    "description": "user can read report",
    "module": "AD"
  }
}
```

### Update data

```
METHOD : PUT
URL : /api/permission
```
**Request Parameter**
```
Json root name : permission
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| id         | Long  ||
| code         | String  ||
| description      | String ||
| module     | String    ||

**Request example**
```json
{
  "permision": {
    "id": 2,
    "code": "permission1",
    "description": "permission1_detail",
    "module": "app_user5"
  }
}
```

### Find one

```
METHOD : GET
URL : /api/permission/{id}
EXAMPLE : /api/permission/1
```
**Response success example** :tada:
```json
{
  "id": 1,
  "code": "api_client_list",
  "description": "api_client_list",
  "module": "AD"
}
```
### Delete data

```
METHOD : DELETE
URL : /api/permission/{id}
EXAMPLE : /api/permission/1
```
---

## Role

### Retrieve data

```
METHOD : GET
URL : /api/role?page={currentPage}&size={size}&sort={#sortField,#sortType}
EXAMPLE : /api/role?page=0&size=2&sort=code,asc
```
**Request Parameter**

| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| page         | Int  ||
| size      | Int ||
| sort     | string,string    |example `createdDate,asc`|

**Response success example** :tada:
```json
{
    "dataList": [
        {
            "id": 1,
            "name": "develop",
            "description": "developer",
            "status": true,
            "selectdPermissions": null
        }
    ],
    "totalPages": 1,
    "totalElements": 1,
    "last": true
}
```
### Create data

```
METHOD : POST
URL : /api/role
```
**Request Parameter**
```
Json root name : role
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| code         | String  ||
| description      | String ||
| status     | Boolean    ||
| selectdPermissions     | Long[]    | |

**Request example**
```json
{
  "role": {
    "name": "develop",
    "description": "developer 555",
    "status": true,
    "selectdPermissions": [
      1,
      2,
      3,
      4
    ]
  }
}
```

### Update data

```
METHOD : PUT
URL : /api/role
```
**Request Parameter**
```
Json root name : permission
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| id         | Long  ||
| code         | String  ||
| description      | String ||
| status     | Boolean    ||
| selectdPermissions     | Long[]    | |
**Request example**
```json
{
  "role": {
    "id": 55,
    "name": "develop",
    "description": "developer",
    "status": true,
    "selectdPermissions": [
      1,
      2
    ]
  }
}
```

### Find one

```
METHOD : GET
URL : /api/role/{id}
EXAMPLE : /api/role/1
```
**Response success example** :tada:
```json
{
  "id": 1,
  "name": "develop",
  "description": "developer",
  "status": true,
  "selectdPermissions": null
}
```

### Delete data

```
METHOD : DELETE
URL : /api/role/{id}
EXAMPLE : /api/role/1
```

---

## User
### Create data

```
METHOD : POST
URL : /api/user
```
**Request Parameter**
```
Json root name : userRegister
```
| Key                  | Data type                            | Description   |
| -------------------- |----------------------------------| --------------|
| email         | String  |unique|
| username      | String |unique|
| password     | String    ||
| selectedRoles     | Long[]    ||

```json
{
  "userRegister": {
    "email": "admin@mydomain.com",
    "username": "admin",
    "password": "1234",
    "selectedRoles": [
      1,2
    ]
  }
}
```

**Response fail example** :imp:

```json
{
  "status": "BAD_REQUEST",
  "message": "Error",
  "errors": [
    "Username admin already exists. ",
    "Email admin@mydomain.com already exists. "
  ],
  "timestamp": "2021-05-05 09:02:24"
}
```
---
## ACL(Access control list)

**Access control list example usage**

Just add an annotation `@PreAuthorize("isHasPermission('{PERMISSION_NAME}||{PERMISSION_NAME2}||{PERMISSION_NAME3}')")` to method in controller.

```java
package com.bekaku.api.spring.controller.api;

@RequestMapping(path = "/api/role")
@RestController
@RequiredArgsConstructor
public class RoleController extends BaseApiController {
    private final RoleService roleService;
    private final PermissionService permissionService;
    private final I18n i18n;
    private final RoleValidator roleValidator;

    Logger logger = LoggerFactory.getLogger(RoleController.class);

    @Value("${app.loging.enable}")
    boolean logEnable;

    @PreAuthorize("isHasPermission('role_list')")
    @GetMapping
    public ResponseEntity<Object> findAll(Pageable pageable) {
        logger.info("/api/role > findAll, isLogEnable {}", logEnable);
        return this.responseEntity(roleService.findAllWithPaging(!pageable.getSort().isEmpty() ? pageable :
                PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Role.getSort())), HttpStatus.OK);
    }

    @PreAuthorize("isHasPermission('role_add||user_manage')")
    @PostMapping
    public ResponseEntity<Object> create(@Valid @RequestBody RoleDto dto) {
        Role role = roleService.convertDtoToEntity(dto);
        roleValidator.validate(role);
        setRolePermission(dto, role);
        roleService.save(role);
        return this.responseEntity(roleService.convertEntityToDto(role), HttpStatus.CREATED);
    }

    private void setRolePermission(RoleDto dto, Role role) {
        if (dto.getSelectdPermissions().length > 0) {
            Optional<Permission> permission;
            for (long permissionId : dto.getSelectdPermissions()) {
                permission = permissionService.findById(permissionId);
                permission.ifPresent(value -> role.getPermissions().add(value));
            }
        }
    }
}
```

**Access is denied response example** :imp:

```json
{
  "status": "INTERNAL_SERVER_ERROR",
  "message": "Access is denied",
  "errors": [
    "error occurred"
  ],
  "timestamp": "2021-05-05 09:03:45"
}
```
## Auto generate starter source

### Create model class

Add an annotation `@GenSourceableTable` to indicate that you want to create Auto source.

```java
package com.bekaku.api.spring.model;

import annotation.com.bekaku.api.spring.GenSourceableTable;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.domain.Sort;

import jakarta.persistence.*;

@GenSourceableTable
@NoArgsConstructor
@Getter
@Setter
@Entity
public class Role extends BaseEntity {

    @Column(name = "name", length = 100, nullable = false, unique = true)
    private String name;

    @Column(name = "description", columnDefinition = "text default null")
    private String description;

    @Column(name = "status", columnDefinition = "tinyint(1) default 1")
    private Boolean status;

    public static Sort getSort() {
        return Sort.by(Sort.Direction.ASC, "name");
    }
}
```

### Generate starter source

Call `http://localhost:{your_server_port}/dev/development/generateSrc` to auto generate source
```
METHOD : POST
URL : dev/development/generateSrc
```

The system will generate the following files.

1. `RoleDto` dto Package
2. `RoleRepository` repository Package
3. `RoleService` service Package
4. `RoleServiceImpl` serviceImpl Package
5. `RoleController` api.controller Package

If you use my [vue-quasar-example-app](https://github.com/bekaku/vue-quasar-example-app) You can create frontend List.vue and Form.vue by adding additional annotaion 'createFrontend = true' Call `http://localhost:{your_server_port}/dev/development/generateSrc` to auto generate source 

It will be created at `build\generated\frontend`
```java
@GenSourceableTable(createFrontend = true)
public class Role extends BaseEntity {

}
```
---


