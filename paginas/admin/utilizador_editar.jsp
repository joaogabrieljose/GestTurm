<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfilSessao = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfilSessao == null || userIdObj == null || !"ADMINISTRADOR".equalsIgnoreCase(perfilSessao)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("utilizadores.jsp?erro=id_invalido");
    return;
}

int id = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nome = "";
String email = "";
String perfil = "";
int ativo = 1;
String numeroAluno = "";
String curso = "";
String anoCurricular = "";

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "u.id, u.nome, u.email, u.perfil, u.ativo, " +
        "COALESCE(a.numero_aluno, '') AS numero_aluno, " +
        "COALESCE(a.curso, c.curso, '') AS curso, " +
        "COALESCE(a.ano_curricular, '') AS ano_curricular " +
        "FROM utilizadores u " +
        "LEFT JOIN alunos a ON a.utilizador_id = u.id " +
        "LEFT JOIN coordenadores c ON c.utilizador_id = u.id " +
        "WHERE u.id = ? " +
        "LIMIT 1"
    );

    ps.setInt(1, id);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nome = rs.getString("nome");
        email = rs.getString("email");
        perfil = rs.getString("perfil");
        ativo = rs.getInt("ativo");
        numeroAluno = rs.getString("numero_aluno");
        curso = rs.getString("curso");
        anoCurricular = rs.getString("ano_curricular");
    } else {
        response.sendRedirect("utilizadores.jsp?erro=utilizador_nao_encontrado");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar utilizador: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Utilizador - Gesturma</title>
    <link rel="stylesheet" href="../../css/geral.css">
</head>

<body>

<div class="dashboard-container">

    <aside class="sidebar">
        <div class="brand">
            <div class="brand-icon">G</div>
            <span>Gesturma</span>
        </div>

        <nav class="menu">
            <a href="admin.jsp">Dashboard</a>
            <a href="utilizadores.jsp" class="active">Utilizadores</a>
            <a href="disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>
    </aside>

    <main class="main-content">

        <section class="page-header">
            <h1>Editar Utilizador</h1>
            <p>Atualiza os dados do utilizador selecionado.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <form action="utilizador_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= id %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome completo</label>
                            <input type="text" name="nome" value="<%= nome %>" required>
                        </div>

                        <div class="form-group">
                            <label>Email</label>
                            <input type="email" name="email" value="<%= email %>" required>
                        </div>

                        <div class="form-group">
                            <label>Nova password</label>
                            <input type="password" name="password" placeholder="Deixa vazio para manter a atual">
                        </div>

                        <div class="form-group">
                            <label>Perfil</label>
                            <select name="perfil" id="perfilSelect" required>
                                <option value="ADMINISTRADOR" <%= "ADMINISTRADOR".equals(perfil) ? "selected" : "" %>>
                                    Administrador
                                </option>

                                <option value="COORDENADOR" <%= "COORDENADOR".equals(perfil) ? "selected" : "" %>>
                                    Coordenador
                                </option>

                                <option value="ALUNO" <%= "ALUNO".equals(perfil) ? "selected" : "" %>>
                                    Aluno
                                </option>
                            </select>
                        </div>

                        <div class="form-group perfil-extra aluno-extra">
                            <label>Número de aluno</label>
                            <input type="text" name="numero_aluno" value="<%= numeroAluno %>">
                        </div>

                        <div class="form-group perfil-extra aluno-extra coordenador-extra">
                            <label>Curso</label>
                            <input type="text" name="curso" value="<%= curso %>">
                        </div>

                        <div class="form-group perfil-extra aluno-extra">
                            <label>Ano curricular</label>
                            <input type="number" name="ano_curricular" min="1" max="5" value="<%= anoCurricular %>">
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="ativo" required>
                                <option value="1" <%= ativo == 1 ? "selected" : "" %>>
                                    Ativo
                                </option>

                                <option value="0" <%= ativo == 0 ? "selected" : "" %>>
                                    Inativo
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="utilizadores.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Utilizador
                        </button>
                    </div>

                </form>

            </div>
        </section>

    </main>

</div>

<script>
    const perfilSelect = document.getElementById("perfilSelect");
    const extras = document.querySelectorAll(".perfil-extra");
    const alunoExtras = document.querySelectorAll(".aluno-extra");
    const coordenadorExtras = document.querySelectorAll(".coordenador-extra");

    function atualizarCamposPerfil() {
        extras.forEach(function(campo) {
            campo.style.display = "none";
        });

        if (perfilSelect.value === "ALUNO") {
            alunoExtras.forEach(function(campo) {
                campo.style.display = "block";
            });
        }

        if (perfilSelect.value === "COORDENADOR") {
            coordenadorExtras.forEach(function(campo) {
                campo.style.display = "block";
            });
        }
    }

    perfilSelect.addEventListener("change", atualizarCamposPerfil);
    atualizarCamposPerfil();
</script>

</body>
</html>