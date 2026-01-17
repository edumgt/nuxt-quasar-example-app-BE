# WSL(Ubuntu) + VSCode 환경에서 실행하기

이 문서는 **WSL 기반 Ubuntu + VSCode(원격 WSL)** 환경에서 이 프로젝트를 실행하기 위해 필요한 **라이브러리 설치**, **소스 설정 변경**, **Docker 설정 변경** 과정을 정리합니다.

## 1) 사전 준비

### 1-1. WSL/VSCode 기본 구성

- Windows에서 WSL2 및 Ubuntu 설치
- VSCode에 **Remote - WSL** 확장 설치
- VSCode로 Ubuntu WSL 환경 열기 (좌측 하단 `><` → WSL)

### 1-2. 필수 패키지 설치 (Ubuntu)

```bash
sudo apt update
sudo apt install -y git curl unzip openjdk-17-jdk
```

> 이 프로젝트는 `Java 17`을 사용합니다 (`build.gradle`의 `toolchain` 설정).

### 1-3. Docker 설치

WSL에서 Docker를 사용할 경우 보통 **Docker Desktop + WSL integration**을 사용합니다.

- Windows에 Docker Desktop 설치
- Docker Desktop → Settings → Resources → WSL Integration에서 Ubuntu 활성화
- WSL 터미널에서 Docker 동작 확인

```bash
docker --version
docker compose version
```

## 2) 데이터/로그 디렉터리 준비

프로젝트에서 파일 저장 및 로그 경로로 사용될 디렉터리를 WSL 환경에 맞게 준비합니다.

```bash
mkdir -p ~/spring-data/logs
```

## 3) 소스 설정 변경 (WSL 경로 반영)

WSL에서는 Windows 경로(`D:/...`) 대신 **Linux 경로**를 사용해야 합니다.

### 3-1. `application-dev.yml` 경로 수정

`src/main/resources/application-dev.yml`에서 다음 항목을 **Linux 경로**로 바꿉니다.

- `app.cdn-directory`: `~/spring-data/` 형태의 경로 사용
- `logging.file.path`: `${app.cdn-directory}logs`로 유지 가능

예시:

```yml
app:
  cdn-directory: /home/<your-user>/spring-data/
```

### 3-2. `log4j2-dev.xml` 로그 경로 수정

`src/main/resources/log4j2-dev.xml`에서 `APP_LOG_ROOT`를 WSL 경로로 바꿉니다.

예시:

```xml
<Property name="APP_LOG_ROOT">/home/<your-user>/spring-data/logs</Property>
```

> 개발 환경에서 `log4j2-dev.xml`이 사용되므로 경로 수정이 필요합니다.

### 3-3. DB 접속 설정 확인

`application-dev.yml`의 `spring.datasource` 설정을 WSL 환경에 맞게 수정합니다.

예시 (로컬 DB 또는 Docker MySQL에 맞춤):

```yml
spring:
  datasource:
    url: jdbc:mysql://${MYSQL_HOST:localhost}:3308/spring_starter?allowPublicKeyRetrieval=true&useSSL=false
    username: root
    password: <your-password>
```

## 4) Docker 설정 변경 (WSL 경로 반영)

`docker-compose.yml`의 volume 경로가 `/srv/spring-data`로 고정되어 있습니다. WSL 환경에서는 **홈 디렉터리 경로**로 변경하는 것이 안전합니다.

예시:

```yml
volumes:
  - /home/<your-user>/spring-data:/usr/spring-data
  - /home/<your-user>/spring-data/logs:/usr/spring-data/logs
```

> 위 경로는 WSL 리눅스 파일 시스템 기준입니다. Windows 경로(`/mnt/c/...`)도 가능하지만 성능 이슈가 있을 수 있습니다.

## 5) 실행 방법

### 5-1. 로컬 실행 (WSL에서 직접 실행)

```bash
./gradlew bootRun
```

또는 개발 프로파일로 실행:

```bash
./gradlew runDev
```

### 5-2. Docker 실행

```bash
docker compose build
docker compose up -d
```

컨테이너 포트 매핑은 기본적으로 `9080 -> 8080`, `9081 -> 8080`으로 되어 있습니다.

## 6) 참고

- API 문서: `/api-docs`, `/swagger-ui/index.html`
- 기본 서버 포트: `8080`
- 개발 프로파일: `spring.profiles.active=dev`

---

필요 시 위 설정을 기반으로 팀 환경에 맞는 `.env` 파일 또는 별도 `application-wsl.yml`을 추가하여 설정을 분리하는 것을 권장합니다.
