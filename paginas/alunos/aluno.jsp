<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
/* =========================================
   PROTEÇÃO DE ACESSO
========================================= */
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"ALUNO".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

/* =========================================
   DADOS DO ALUNO
========================================= */
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

int alunoId = 0;
String nomeAluno = "";
String emailAluno = "";
String numeroAluno = "";
String cursoAluno = "";
int anoCurricular = 0;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "a.id AS aluno_id, " +
        "u.nome, u.email, " +
        "a.numero_aluno, a.curso, a.ano_curricular " +
        "FROM utilizadores u " +
        "INNER JOIN alunos a ON a.utilizador_id = u.id " +
        "WHERE u.id = ? " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        alunoId = rs.getInt("aluno_id");
        nomeAluno = rs.getString("nome");
        emailAluno = rs.getString("email");
        numeroAluno = rs.getString("numero_aluno");
        cursoAluno = rs.getString("curso");
        anoCurricular = rs.getInt("ano_curricular");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=aluno_nao_encontrado");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar os dados do aluno: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "A";

if (nomeAluno != null && nomeAluno.trim().length() > 0) {
    letraAvatar = nomeAluno.substring(0, 1).toUpperCase();
}
%>

<%
/* =========================================
   MINHAS INSCRIÇÕES
========================================= */
Connection conIns = null;
PreparedStatement psIns = null;
ResultSet rsIns = null;

try {
    conIns = dbConnect();

    psIns = conIns.prepareStatement(
        "SELECT " +
        "i.id AS inscricao_id, " +
        "i.estado, " +
        "DATE_FORMAT(i.data_inscricao, '%d/%m/%Y %H:%i') AS data_inscricao, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.nome AS turma, " +
        "t.tipo, " +
        "COALESCE( " +
        "   GROUP_CONCAT( " +
        "       CONCAT( " +
        "           h.dia_semana, ' ', " +
        "           TIME_FORMAT(h.hora_inicio, '%H:%i'), ' - ', " +
        "           TIME_FORMAT(h.hora_fim, '%H:%i'), ' | ', h.sala " +
        "       ) SEPARATOR ' / ' " +
        "   ), " +
        "   'Horário ainda não definido' " +
        ") AS horario " +
        "FROM inscricoes i " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN turmas t ON t.id = i.turma_id " +
        "LEFT JOIN horarios h ON h.turma_id = t.id " +
        "WHERE i.aluno_id = ? " +
        "GROUP BY " +
        "i.id, i.estado, i.data_inscricao, " +
        "d.nome, d.codigo, t.nome, t.tipo " +
        "ORDER BY i.data_inscricao DESC"
    );

    psIns.setInt(1, alunoId);
    rsIns = dbQuery(conIns, psIns);

} catch (Exception e) {
    out.print("Erro ao carregar inscrições: " + e.getMessage());
}
%>

<%
/* =========================================
   TURMAS DISPONÍVEIS
========================================= */
Connection conTurmas = null;
PreparedStatement psTurmas = null;
ResultSet rsTurmas = null;

try {
    conTurmas = dbConnect();

    psTurmas = conTurmas.prepareStatement(
        "SELECT " +
        "d.id AS disciplina_id, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.id AS turma_id, " +
        "t.nome AS turma, " +
        "t.tipo, " +
        "t.capacidade_minima, " +
        "t.capacidade_maxima, " +
        "COALESCE(ins.total_inscritos, 0) AS total_inscritos, " +
        "(t.capacidade_maxima - COALESCE(ins.total_inscritos, 0)) AS vagas_disponiveis, " +
        "COALESCE(h.lista_horarios, 'Horário ainda não definido') AS horario, " +
        "CASE " +
        "   WHEN pi.ativo = 1 " +
        "   AND NOW() BETWEEN pi.data_inicio AND pi.data_fim " +
        "   THEN 'ABERTO' " +
        "   ELSE 'FECHADO' " +
        "END AS estado_periodo " +
        "FROM turmas t " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "LEFT JOIN periodos_inscricao pi ON pi.disciplina_id = d.id " +
        "LEFT JOIN ( " +
        "   SELECT turma_id, COUNT(*) AS total_inscritos " +
        "   FROM inscricoes " +
        "   WHERE estado = 'ATIVA' " +
        "   GROUP BY turma_id " +
        ") ins ON ins.turma_id = t.id " +
        "LEFT JOIN ( " +
        "   SELECT " +
        "   turma_id, " +
        "   GROUP_CONCAT( " +
        "       CONCAT( " +
        "           dia_semana, ' ', " +
        "           TIME_FORMAT(hora_inicio, '%H:%i'), ' - ', " +
        "           TIME_FORMAT(hora_fim, '%H:%i'), ' | ', sala " +
        "       ) SEPARATOR ' / ' " +
        "   ) AS lista_horarios " +
        "   FROM horarios " +
        "   GROUP BY turma_id " +
        ") h ON h.turma_id = t.id " +
        "WHERE t.ativo = 1 " +
        "AND d.ativo = 1 " +
        "ORDER BY d.nome, t.nome"
    );

    rsTurmas = dbQuery(conTurmas, psTurmas);

} catch (Exception e) {
    out.print("Erro ao carregar turmas disponíveis: " + e.getMessage());
}
%>

<%
/* =========================================
   HORÁRIOS
========================================= */
Connection conHorarios = null;
PreparedStatement psHorarios = null;
ResultSet rsHorarios = null;

try {
    conHorarios = dbConnect();

    psHorarios = conHorarios.prepareStatement(
        "SELECT " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "t.nome AS turma, " +
        "t.tipo, " +
        "h.dia_semana, " +
        "TIME_FORMAT(h.hora_inicio, '%H:%i') AS hora_inicio, " +
        "TIME_FORMAT(h.hora_fim, '%H:%i') AS hora_fim, " +
        "h.sala " +
        "FROM horarios h " +
        "INNER JOIN turmas t ON t.id = h.turma_id " +
        "INNER JOIN disciplinas d ON d.id = t.disciplina_id " +
        "WHERE t.ativo = 1 " +
        "AND d.ativo = 1 " +
        "ORDER BY " +
        "FIELD(h.dia_semana, 'SEGUNDA', 'TERCA', 'QUARTA', 'QUINTA', 'SEXTA', 'SABADO'), " +
        "h.hora_inicio, d.nome, t.nome"
    );

    rsHorarios = dbQuery(conHorarios, psHorarios);

} catch (Exception e) {
    out.print("Erro ao carregar horários: " + e.getMessage());
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Aluno - Gesturma</title>
    <link rel="stylesheet" href="../../css/geral.css">
</head>
<body>

<div class="dashboard-container">

    <!-- MENU LATERAL -->
    <aside class="sidebar">
        <div class="brand">
            <div class="brand-icon">G</div>
            <span>Gesturma</span>
        </div>

        <nav class="menu">
            <a href="aluno.jsp" class="active">Dashboard</a>
            <a href="#" id="abrirInscricoesLink">Minhas Inscrições</a>
            <a href="#" id="abrirTurmasLink">Turmas Disponíveis</a>
            <a href="#" id="abrirHorariosLink">Horários</a>
            <a href="#" id="abrirPerfilLink">Meu Perfil</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>
    </aside>

    <!-- CONTEÚDO PRINCIPAL -->
    <main class="main-content">
        <!-- TOPO -->
        <header class="topbar">
            <div class="search-box">
                <input type="text" placeholder="Pesquisar...">
            </div>

            <div class="topbar-right">
                <div class="notification"></div>

                <div class="user-box">
                    <div class="user-avatar">
                        <%= letraAvatar %>
                    </div>

                    <div class="user-info">
                        <strong><%= nomeAluno %></strong>
                        <span>Aluno</span>
                    </div>
                </div>
            </div>
        </header>

        <!-- TÍTULO -->
        <section class="page-header">
            <h1>Dashboard do Aluno</h1>
            <p>Bem-vindo ao Gesturma. Aqui podes acompanhar os teus dados académicos.</p>
        </section>

        <!-- CARTÕES -->
        <section class="cards-grid">
            <div class="info-card blue">
                <h3>Nome</h3>
                <p><%= nomeAluno %></p>
            </div>

            <div class="info-card green">
                <h3>Número de Aluno</h3>
                <p><%= numeroAluno %></p>
            </div>

            <div class="info-card orange">
                <h3>Curso</h3>
                <p><%= cursoAluno %></p>
            </div>

            <div class="info-card pink">
                <h3>Ano Curricular</h3>
                <p><%= anoCurricular %>º Ano</p>
            </div>
        </section>

        <!-- PERFIL -->
        <section class="profile-section">
            <div class="profile-card">
                <h2>Dados do Aluno</h2>

                <div class="profile-grid">
                    <div class="profile-item">
                        <span>Nome completo</span>
                        <strong><%= nomeAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Email</span>
                        <strong><%= emailAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Número de aluno</span>
                        <strong><%= numeroAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Curso</span>
                        <strong><%= cursoAluno %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Ano curricular</span>
                        <strong><%= anoCurricular %>º Ano</strong>
                    </div>

                    <div class="profile-item">
                        <span>Perfil</span>
                        <strong>Aluno</strong>
                    </div>
                </div>
            </div>
        </section>

    </main>
</div>


<!-- MODAL: MINHAS INSCRIÇÕES -->
<div id="inscricoesModal" class="modal">
    <div class="modal-box modal-wide">
        <div class="modal-top">
            <h2>Minhas Inscrições</h2>
            <a href="#" class="modal-close" id="fecharInscricoesLink">✕</a>
        </div>
        <div class="inscricoes-lista">
            <%
                boolean temInscricoes = false;

                if (rsIns != null) {
                    while (rsIns.next()) {
                        temInscricoes = true;
            %>
                <article class="inscricao-card">
                    <div class="inscricao-top">
                        <div>
                            <h3><%= rsIns.getString("disciplina") %></h3>
                        </div>
                        <strong class="estado-inscricao">
                            <%= rsIns.getString("estado") %>
                        </strong>
                    </div>
                    <p>
                        <strong>Turma:</strong>
                        <%= rsIns.getString("turma") %>
                    </p>
                    <p>
                        <strong>Tipo:</strong>
                        <%= rsIns.getString("tipo").replace("_", " ") %>
                    </p>
                    <p>
                        <strong>Horário:</strong>
                        <%= rsIns.getString("horario") %>
                    </p>
                    <p>
                        <strong>Data da inscrição:</strong>
                        <%= rsIns.getString("data_inscricao") %>
                    </p>
                </article>
            <%
                    }
                }

                if (!temInscricoes) {
            %>
                <div class="empty-modal-message">
                    Ainda não tens inscrições registadas.
                </div>

            <%
                }
            %>

        </div>
    </div>
</div>


<!-- MODAL: TURMAS DISPONÍVEIS -->
<div id="turmasModal" class="modal">
    <div class="modal-box modal-wide">

        <div class="modal-top">
            <h2>Turmas Disponíveis</h2>
            <a href="#" class="modal-close" id="fecharTurmasLink">✕</a>
        </div>
        <div class="turmas-lista">

            <%
                boolean temTurmasDisponiveis = false;

                if (rsTurmas != null) {
                    while (rsTurmas.next()) {
                        temTurmasDisponiveis = true;

                        int vagas = rsTurmas.getInt("vagas_disponiveis");
                        String estadoPeriodo = rsTurmas.getString("estado_periodo");
            %>
                <article class="turma-card">

                    <div class="turma-top">
                        <div>
                            <h3><%= rsTurmas.getString("disciplina") %></h3>
                        </div>
                        <strong class="<%= "ABERTO".equals(estadoPeriodo) ? "periodo-aberto" : "periodo-fechado" %>">
                            <%= estadoPeriodo %>
                        </strong>
                    </div>
                    <p>
                        <strong>Turma:</strong>
                        <%= rsTurmas.getString("turma") %>
                    </p>
                    <p>
                        <strong>Tipo:</strong>
                        <%= rsTurmas.getString("tipo").replace("_", " ") %>
                    </p>

                    <p>
                        <strong>Horário:</strong>
                        <%= rsTurmas.getString("horario") %>
                    </p>

                    <div class="turma-vagas">
                        <span>
                            <strong>Inscritos:</strong>
                            <%= rsTurmas.getInt("total_inscritos") %> /
                            <%= rsTurmas.getInt("capacidade_maxima") %>
                        </span>

                        <span>
                            <strong>Vagas:</strong>
                            <%= vagas %>
                        </span>
                    </div>
                    <%
                        if ("ABERTO".equals(estadoPeriodo) && vagas > 0) {
                    %>
                        <button class="btn-inscrever" type="button">
                            Inscrever-me
                        </button>
                    <%
                        } else {
                    %>
                        <button class="btn-inscrever disabled" type="button" disabled>
                            Inscrição indisponível
                        </button>
                    <%
                        }
                    %>
                </article>
            <%
                    }
                }
                if (!temTurmasDisponiveis) {
            %>
                <div class="empty-modal-message">
                    Ainda não existem turmas disponíveis.
                </div>
            <%
                }
            %>
        </div>
    </div>
</div>

<!-- MODAL: HORÁRIOS -->
<div id="horariosModal" class="modal">
    <div class="modal-box modal-wide">

        <div class="modal-top">
            <h2>Horários das Turmas</h2>
            <a href="#" class="modal-close" id="fecharHorariosLink">✕</a>
        </div>

        <div class="horarios-lista">

            <%
                boolean temHorarios = false;

                if (rsHorarios != null) {
                    while (rsHorarios.next()) {
                        temHorarios = true;
            %>

                <article class="horario-card">

                    <div class="horario-dia">
                        <strong><%= rsHorarios.getString("dia_semana") %></strong>
                        <span>
                            <%= rsHorarios.getString("hora_inicio") %>
                            -
                            <%= rsHorarios.getString("hora_fim") %>
                        </span>
                    </div>

                    <div class="horario-info">
                        <h3><%= rsHorarios.getString("disciplina") %></h3>

                        <p>
                            <strong>Código:</strong>
                            <%= rsHorarios.getString("codigo_disciplina") %>
                        </p>

                        <p>
                            <strong>Turma:</strong>
                            <%= rsHorarios.getString("turma") %>
                        </p>

                        <p>
                            <strong>Tipo:</strong>
                            <%= rsHorarios.getString("tipo").replace("_", " ") %>
                        </p>

                        <p>
                            <strong>Sala:</strong>
                            <%= rsHorarios.getString("sala") %>
                        </p>
                    </div>

                </article>

            <%
                    }
                }

                if (!temHorarios) {
            %>

                <div class="empty-modal-message">
                    Ainda não existem horários registados.
                </div>

            <%
                }
            %>

        </div>
    </div>
</div>

<!-- MODAL: MEU PERFIL -->
<div id="perfilModal" class="modal">
    <div class="modal-box">

        <div class="modal-top">
            <h2>Meu Perfil</h2>
            <a href="#" class="modal-close" id="fecharPerfilLink">✕</a>
        </div>

        <div class="perfil-modal-content">

            <div class="perfil-avatar-grande">
                <%= letraAvatar %>
            </div>

            <h3><%= nomeAluno %></h3>
            <p class="perfil-subtitulo">Aluno do Gesturma</p>

            <div class="perfil-dados-lista">

                <div class="perfil-dado-linha">
                    <span>Nome completo</span>
                    <strong><%= nomeAluno %></strong>
                </div>

                <div class="perfil-dado-linha">
                    <span>Email</span>
                    <strong><%= emailAluno %></strong>
                </div>

                <div class="perfil-dado-linha">
                    <span>Número de aluno</span>
                    <strong><%= numeroAluno %></strong>
                </div>

                <div class="perfil-dado-linha">
                    <span>Curso</span>
                    <strong><%= cursoAluno %></strong>
                </div>

                <div class="perfil-dado-linha">
                    <span>Ano curricular</span>
                    <strong><%= anoCurricular %>º Ano</strong>
                </div>

                <div class="perfil-dado-linha">
                    <span>Perfil</span>
                    <strong>Aluno</strong>
                </div>

            </div>

        </div>

    </div>
</div>


<script>
    const inscricoesModal = document.getElementById("inscricoesModal");
    const abrirInscricoes = document.getElementById("abrirInscricoesLink");
    const fecharInscricoes = document.getElementById("fecharInscricoesLink");

    if (abrirInscricoes) {
        abrirInscricoes.addEventListener("click", function(e) {
            e.preventDefault();
            inscricoesModal.classList.add("show");
        });
    }

    if (fecharInscricoes) {
        fecharInscricoes.addEventListener("click", function(e) {
            e.preventDefault();
            inscricoesModal.classList.remove("show");
        });
    }

    if (inscricoesModal) {
        inscricoesModal.addEventListener("click", function(e) {
            if (e.target.id === "inscricoesModal") {
                inscricoesModal.classList.remove("show");
            }
        });
    }

    document.addEventListener("keydown", function(e) {
        if (e.key === "Escape") {
            inscricoesModal.classList.remove("show");
        }
    });

    const turmasModal = document.getElementById("turmasModal");
    const abrirTurmas = document.getElementById("abrirTurmasLink");
    const fecharTurmas = document.getElementById("fecharTurmasLink");

    if (abrirTurmas) {
        abrirTurmas.addEventListener("click", function(e) {
            e.preventDefault();
            turmasModal.classList.add("show");
        });
    }

    if (fecharTurmas) {
        fecharTurmas.addEventListener("click", function(e) {
            e.preventDefault();
            turmasModal.classList.remove("show");
        });
    }

    if (turmasModal) {
        turmasModal.addEventListener("click", function(e) {
            if (e.target.id === "turmasModal") {
                turmasModal.classList.remove("show");
            }
        });
    }

    const horariosModal = document.getElementById("horariosModal");
    const abrirHorarios = document.getElementById("abrirHorariosLink");
    const fecharHorarios = document.getElementById("fecharHorariosLink");

    if (abrirHorarios) {
        abrirHorarios.addEventListener("click", function(e) {
            e.preventDefault();
            horariosModal.classList.add("show");
        });
    }

    if (fecharHorarios) {
        fecharHorarios.addEventListener("click", function(e) {
            e.preventDefault();
            horariosModal.classList.remove("show");
        });
    }

    if (horariosModal) {
        horariosModal.addEventListener("click", function(e) {
            if (e.target.id === "horariosModal") {
                horariosModal.classList.remove("show");
            }
        });
    }

    const perfilModal = document.getElementById("perfilModal");
    const abrirPerfil = document.getElementById("abrirPerfilLink");
    const fecharPerfil = document.getElementById("fecharPerfilLink");

    if (abrirPerfil) {
        abrirPerfil.addEventListener("click", function(e) {
            e.preventDefault();
            perfilModal.classList.add("show");
        });
    }

    if (fecharPerfil) {
        fecharPerfil.addEventListener("click", function(e) {
            e.preventDefault();
            perfilModal.classList.remove("show");
        });
    }

    if (perfilModal) {
        perfilModal.addEventListener("click", function(e) {
            if (e.target.id === "perfilModal") {
                perfilModal.classList.remove("show");
            }
        });
    }
</script>



</body>
</html>