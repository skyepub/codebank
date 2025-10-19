use spacl;

CREATE TABLE member (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,

    role_id BIGINT UNSIGNED DEFAULT 1 COMMENT '기본: 학생',
    school_id BIGINT UNSIGNED DEFAULT NULL,

    admission_year INT DEFAULT NULL,
    grade_adjustment INT DEFAULT 0,

    gender BOOLEAN DEFAULT NULL COMMENT 'TRUE=남, FALSE=여',
    birth_date DATE DEFAULT NULL,

    -- 🔐 JWT / 인증 관련 필드
    refresh_token VARCHAR(512) DEFAULT NULL,
    refresh_token_expire_at DATETIME DEFAULT NULL,
    last_login_at DATETIME DEFAULT NULL,
    login_fail_count INT DEFAULT 0,
    is_locked BOOLEAN DEFAULT FALSE,

    meta JSON DEFAULT NULL,

    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE member_relation (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    source_member_id BIGINT UNSIGNED NOT NULL COMMENT '관계를 맺는 주체 (교사/부모)',
    target_member_id BIGINT UNSIGNED NOT NULL COMMENT '관계를 받는 대상 (학생)',

    meta JSON DEFAULT NULL COMMENT '관계 부가정보 (예: {"subject":"국어", "homeroom":true})',
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_member_relation (source_member_id, target_member_id)
);

CREATE TABLE role (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    code VARCHAR(50) NOT NULL UNIQUE COMMENT '내부 시스템 코드 (예: STUDENT, PARENT, TEACHER, ADMIN)',
    name VARCHAR(50) NOT NULL COMMENT '표시용 이름 (예: 학생, 학부모, 교사, 관리자)',

    description VARCHAR(255) DEFAULT NULL COMMENT '설명 또는 비고',
    level INT DEFAULT 0 COMMENT '권한 수준 (높을수록 관리자 권한)',

    meta JSON DEFAULT NULL COMMENT '확장 속성 (예: color, dashboard_visible 등)',
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO role (code, name, description, level, meta, is_deleted)
VALUES
('STUDENT', '학생', '일반 사용자 (학습자)', 0, JSON_OBJECT('default', true), FALSE),
('PARENT', '학부모', '학생의 보호자, 자녀 조회 가능', 1, JSON_OBJECT('children_visible', true), FALSE),
('TEACHER', '교사', '학생 및 학급 관리 가능', 2, JSON_OBJECT('manage_students', true), FALSE),
('ADMIN', '관리자', '시스템 전체 관리 권한', 10, JSON_OBJECT('superuser', true), FALSE);


CREATE TABLE school (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    school_code VARCHAR(20) DEFAULT NULL COMMENT '교육청 고유 코드 (있을 경우)',
    name VARCHAR(200) NOT NULL COMMENT '학교명',

    level ENUM('KINDERGARTEN', 'ELEMENTARY', 'MIDDLE', 'HIGH') NOT NULL COMMENT '학교 급 (유,초,중,고)',
    type VARCHAR(100) DEFAULT NULL COMMENT '학교 세부 유형 (예: 자사고, 특목고, 공립 등)',
    established_type ENUM('PUBLIC', 'PRIVATE', 'NATIONAL') DEFAULT 'PUBLIC' COMMENT '설립 유형',

    region VARCHAR(100) DEFAULT NULL COMMENT '시/도 (예: 서울특별시)',
    district VARCHAR(100) DEFAULT NULL COMMENT '시/군/구 (예: 종로구)',
    education_office VARCHAR(100) DEFAULT NULL COMMENT '교육지원청 (예: 중부)',
    postal_code VARCHAR(10) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    phone VARCHAR(50) DEFAULT NULL,
    fax VARCHAR(50) DEFAULT NULL,
    homepage VARCHAR(255) DEFAULT NULL,

    campus_type ENUM('MAIN', 'BRANCH') DEFAULT 'MAIN' COMMENT '본교/분교 여부',
    status ENUM('ACTIVE', 'CLOSED') DEFAULT 'ACTIVE' COMMENT '학교 상태',

    meta JSON DEFAULT NULL COMMENT '추가 정보 (비고, 좌표, 메모 등)',
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE study_block (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    textbook_id BIGINT UNSIGNED NOT NULL COMMENT '교과서 ID (textbook 테이블 참조)',
    start_page INT NOT NULL COMMENT '시작 페이지',
    end_page INT NOT NULL COMMENT '끝 페이지',
    repeat_goal INT DEFAULT 10 COMMENT '반복 목표 횟수',

    file_type ENUM('PDF', 'GIF', 'PNG', 'JPG', 'WEBP') DEFAULT 'PDF' COMMENT '학습자료 형식',
    file_url VARCHAR(512) NOT NULL COMMENT '파일 URL',

    meta JSON DEFAULT NULL COMMENT '추가정보 (예: 학습 난이도, 메모 등)',
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE study_block_record (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    set_id BIGINT UNSIGNED NOT NULL COMMENT 'StudyBlockSet 참조',
    study_block_id BIGINT UNSIGNED NOT NULL COMMENT '원본 StudyBlock 참조',
    member_id BIGINT UNSIGNED NOT NULL COMMENT '학생(Member)',
    teacher_id BIGINT UNSIGNED DEFAULT NULL COMMENT '채점자(Teacher)',

    set_order INT DEFAULT 0 COMMENT '세트 내 순서 (0부터 시작, 자유 재배치 가능)',

    attempt_no INT DEFAULT 1 COMMENT '시행 회차',
    score DECIMAL(5,2) DEFAULT NULL COMMENT '점수',
    duration_sec INT DEFAULT NULL COMMENT '학습 소요시간(초, 직접 지정)',
    answers JSON DEFAULT NULL COMMENT '답안 데이터 (문항별 JSON 구조)',

    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '답안 제출 시각',
    scored_at DATETIME DEFAULT NULL COMMENT '채점 시각',

    meta JSON DEFAULT NULL COMMENT '추가 정보 (디바이스, 상태 등)',
    is_deleted BOOLEAN DEFAULT FALSE COMMENT '논리 삭제 여부',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_set (set_id),
    INDEX idx_member (member_id)
);

CREATE TABLE study_block_set (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    member_id BIGINT UNSIGNED NOT NULL COMMENT '학생(Member)',
    title VARCHAR(200) DEFAULT NULL COMMENT '세트 제목 (예: 2025-10-20 학습 세트)',
    set_date DATE NOT NULL COMMENT '세트 시행일자 (실제 학습 수행일)',

    started_at DATETIME DEFAULT NULL COMMENT '세트 실제 시작 시각',
    ended_at DATETIME DEFAULT NULL COMMENT '세트 실제 종료 시각',

    total_score DECIMAL(5,2) DEFAULT NULL COMMENT '세트 전체 평균 점수',
    description VARCHAR(255) DEFAULT NULL COMMENT '세트 설명 (예: 국영수 복습)',

    meta JSON DEFAULT NULL COMMENT '추가 정보 (기기, 환경, 태그 등)',
    is_deleted BOOLEAN DEFAULT FALSE COMMENT '논리 삭제 여부',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시각',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시각'
);








