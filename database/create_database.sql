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

-- =====================================================
-- ASSOCIAÇÃO DO COORDENADOR E DO ALUNO
-- =====================================================

INSERT INTO coordenadores (utilizador_id, curso)
VALUES (
    (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt'),
    'Engenharia Informática'
);

INSERT INTO alunos (utilizador_id, numero_aluno, curso, ano_curricular)
VALUES (
    (SELECT id FROM utilizadores WHERE email = 'aluno@gesturma.pt'),
    '20230253',
    'Engenharia Informática',
    2
);


-- =====================================================
-- INSERÇÃO DE DISCIPLINAS INICIAIS 
-- Necessário porque as turmas pertencem a disciplinas
-- =====================================================


INSERT INTO disciplinas 
(coordenador_id, nome, codigo, semestre, ano_letivo, numero_alunos_inscritos, ativo)
VALUES
((SELECT id FROM coordenadores WHERE utilizador_id = (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt')), 'Engenharia de Software', 'ES', 2, '2025/2026', 60, 1),
((SELECT id FROM coordenadores WHERE utilizador_id = (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt')), 'Bases de Dados', 'BD', 2, '2025/2026', 55, 1),
((SELECT id FROM coordenadores WHERE utilizador_id = (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt')), 'Sistemas Operativos', 'SO', 2, '2025/2026', 50, 1),
((SELECT id FROM coordenadores WHERE utilizador_id = (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt')), 'Programação Web', 'PW', 2, '2025/2026', 45, 1),
((SELECT id FROM coordenadores WHERE utilizador_id = (SELECT id FROM utilizadores WHERE email = 'coordenador@gesturma.pt')), 'Redes de Computadores', 'RC', 2, '2025/2026', 48, 1);


-- =====================================================
-- INSERÇÃO DE 10 TURMAS INICIAIS
-- =====================================================

INSERT INTO turmas 
(disciplina_id, nome, tipo, capacidade_minima, capacidade_maxima, ativo)
VALUES
((SELECT id FROM disciplinas WHERE codigo = 'ES'), 'Turma ES-A', 'TEORICO_PRATICA', 15, 30, 1),
((SELECT id FROM disciplinas WHERE codigo = 'ES'), 'Turma ES-B', 'TEORICO_PRATICA', 15, 30, 1),

((SELECT id FROM disciplinas WHERE codigo = 'BD'), 'Turma BD-A', 'LABORATORIAL', 12, 25, 1),
((SELECT id FROM disciplinas WHERE codigo = 'BD'), 'Turma BD-B', 'LABORATORIAL', 12, 25, 1),

((SELECT id FROM disciplinas WHERE codigo = 'SO'), 'Turma SO-A', 'PRATICA', 15, 28, 1),
((SELECT id FROM disciplinas WHERE codigo = 'SO'), 'Turma SO-B', 'PRATICA', 15, 28, 1),

((SELECT id FROM disciplinas WHERE codigo = 'PW'), 'Turma PW-A', 'LABORATORIAL', 12, 24, 1),
((SELECT id FROM disciplinas WHERE codigo = 'PW'), 'Turma PW-B', 'LABORATORIAL', 12, 24, 1),

((SELECT id FROM disciplinas WHERE codigo = 'RC'), 'Turma RC-A', 'TEORICO_PRATICA', 15, 30, 1),
((SELECT id FROM disciplinas WHERE codigo = 'RC'), 'Turma RC-B', 'TEORICO_PRATICA', 15, 30, 1);


-- =====================================================
-- INSERÇÃO DE HORÁRIOS PARA AS 10 TURMAS
-- =====================================================

INSERT INTO horarios 
(turma_id, dia_semana, hora_inicio, hora_fim, sala)
VALUES
((SELECT id FROM turmas WHERE nome = 'Turma ES-A'), 'SEGUNDA', '09:00:00', '11:00:00', 'Sala 1.1'),
((SELECT id FROM turmas WHERE nome = 'Turma ES-B'), 'TERCA', '14:00:00', '16:00:00', 'Sala 1.2'),

((SELECT id FROM turmas WHERE nome = 'Turma BD-A'), 'QUARTA', '10:00:00', '12:00:00', 'Lab 2'),
((SELECT id FROM turmas WHERE nome = 'Turma BD-B'), 'QUINTA', '15:00:00', '17:00:00', 'Lab 3'),

((SELECT id FROM turmas WHERE nome = 'Turma SO-A'), 'SEGUNDA', '11:00:00', '13:00:00', 'Sala 2.1'),
((SELECT id FROM turmas WHERE nome = 'Turma SO-B'), 'SEXTA', '09:00:00', '11:00:00', 'Sala 2.2'),

((SELECT id FROM turmas WHERE nome = 'Turma PW-A'), 'TERCA', '09:00:00', '11:00:00', 'Lab 1'),
((SELECT id FROM turmas WHERE nome = 'Turma PW-B'), 'QUARTA', '14:00:00', '16:00:00', 'Lab 1'),

((SELECT id FROM turmas WHERE nome = 'Turma RC-A'), 'QUINTA', '10:00:00', '12:00:00', 'Sala 3.1'),
((SELECT id FROM turmas WHERE nome = 'Turma RC-B'), 'SEXTA', '14:00:00', '16:00:00', 'Sala 3.2');


-- =====================================================
-- PERÍODOS DE INSCRIÇÃO DAS DISCIPLINAS
-- =====================================================

INSERT INTO periodos_inscricao 
(disciplina_id, data_inicio, data_fim, ativo)
VALUES
((SELECT id FROM disciplinas WHERE codigo = 'ES'), '2026-02-01 00:00:00', '2026-02-15 23:59:59', 1),
((SELECT id FROM disciplinas WHERE codigo = 'BD'), '2026-02-01 00:00:00', '2026-02-15 23:59:59', 1),
((SELECT id FROM disciplinas WHERE codigo = 'SO'), '2026-02-01 00:00:00', '2026-02-15 23:59:59', 1),
((SELECT id FROM disciplinas WHERE codigo = 'PW'), '2026-02-01 00:00:00', '2026-02-15 23:59:59', 1),
((SELECT id FROM disciplinas WHERE codigo = 'RC'), '2026-02-01 00:00:00', '2026-02-15 23:59:59', 1);