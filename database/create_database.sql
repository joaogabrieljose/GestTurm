CREATE DATABASE IF NOT EXISTS gesturma_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE gesturma_db;

DROP TABLE IF EXISTS inscricoes;
DROP TABLE IF EXISTS periodos_inscricao;
DROP TABLE IF EXISTS horarios;
DROP TABLE IF EXISTS turmas;
DROP TABLE IF EXISTS disciplinas;
DROP TABLE IF EXISTS alunos;
DROP TABLE IF EXISTS coordenadores;
DROP TABLE IF EXISTS utilizadores;

CREATE TABLE utilizadores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    perfil ENUM('ADMINISTRADOR', 'COORDENADOR', 'ALUNO') NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE alunos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL UNIQUE,
    numero_aluno VARCHAR(30) NOT NULL UNIQUE,
    curso VARCHAR(120) NOT NULL,
    ano_curricular INT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_alunos_utilizadores
        FOREIGN KEY (utilizador_id)
        REFERENCES utilizadores(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE coordenadores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL UNIQUE,
    curso VARCHAR(120) NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_coordenadores_utilizadores
        FOREIGN KEY (utilizador_id)
        REFERENCES utilizadores(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE disciplinas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    coordenador_id INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    codigo VARCHAR(30) NULL,
    semestre INT NOT NULL,
    ano_letivo VARCHAR(20) NOT NULL,
    numero_alunos_inscritos INT NOT NULL DEFAULT 0,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_disciplinas_coordenadores
        FOREIGN KEY (coordenador_id)
        REFERENCES coordenadores(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE turmas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    disciplina_id INT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    tipo ENUM('TEORICA', 'PRATICA', 'TEORICO_PRATICA', 'LABORATORIAL') NOT NULL,
    capacidade_minima INT NOT NULL,
    capacidade_maxima INT NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_turmas_disciplinas
        FOREIGN KEY (disciplina_id)
        REFERENCES disciplinas(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_turma_disciplina_nome
        UNIQUE (disciplina_id, nome),
    CONSTRAINT uq_turma_id_disciplina
        UNIQUE (id, disciplina_id),
    CONSTRAINT chk_capacidade_turma
        CHECK (capacidade_minima >= 0 AND capacidade_maxima >= capacidade_minima)
) ENGINE=InnoDB;

CREATE TABLE horarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    turma_id INT NOT NULL,
    dia_semana ENUM('SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA', 'SABADO') NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    sala VARCHAR(50) NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_horarios_turmas
        FOREIGN KEY (turma_id)
        REFERENCES turmas(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_horario
        CHECK (hora_fim > hora_inicio)
) ENGINE=InnoDB;

CREATE TABLE periodos_inscricao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    disciplina_id INT NOT NULL UNIQUE,
    data_inicio DATETIME NOT NULL,
    data_fim DATETIME NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_periodos_disciplinas
        FOREIGN KEY (disciplina_id)
        REFERENCES disciplinas(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_periodo_inscricao
        CHECK (data_fim > data_inicio)
) ENGINE=InnoDB;

CREATE TABLE inscricoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aluno_id INT NOT NULL,
    disciplina_id INT NOT NULL,
    turma_id INT NOT NULL,
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('ATIVA', 'CANCELADA', 'ALTERADA') NOT NULL DEFAULT 'ATIVA',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inscricoes_alunos
        FOREIGN KEY (aluno_id)
        REFERENCES alunos(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_inscricoes_disciplinas
        FOREIGN KEY (disciplina_id)
        REFERENCES disciplinas(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_inscricoes_turmas
        FOREIGN KEY (turma_id, disciplina_id)
        REFERENCES turmas(id, disciplina_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_aluno_disciplina
        UNIQUE (aluno_id, disciplina_id)
) ENGINE=InnoDB;


-- =====================================================
-- INSERÇÃO DE UTILIZADORES INICIAIS
-- Password padrão dos três utilizadores: 123456
-- =====================================================

INSERT INTO utilizadores (nome, email, password, perfil, ativo)
VALUES ('Administrador Gesturma','admin@gesturma.pt','123456','ADMINISTRADOR',1);

INSERT INTO utilizadores (nome, email, password, perfil, ativo)
VALUES ('Coordenador Gesturma','coordenador@gesturma.pt','123456','COORDENADOR',1);

INSERT INTO utilizadores (nome, email, password, perfil, ativo)
VALUES ('Aluno Gesturma','aluno@gesturma.pt','123456','ALUNO',1);