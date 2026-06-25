<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../../database/basedados.h" %>

<%
String perfil = (String) session.getAttribute("perfil");
Object userIdObj = session.getAttribute("userId");

if (perfil == null || userIdObj == null || !"COORDENADOR".equalsIgnoreCase(perfil)) {
    response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?acesso=negado");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeCoordenador = "";
String emailCoordenador = "";
String cursoCoordenador = "";
int coordenadorId = 0;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT " +
        "c.id AS coordenador_id, " +
        "u.nome, " +
        "u.email, " +
        "c.curso " +
        "FROM coordenadores c " +
        "INNER JOIN utilizadores u ON u.id = c.utilizador_id " +
        "WHERE u.id = ? " +
        "AND u.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        coordenadorId = rs.getInt("coordenador_id");
        nomeCoordenador = rs.getString("nome");
        emailCoordenador = rs.getString("email");
        cursoCoordenador = rs.getString("curso");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=coordenador_nao_encontrado");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar perfil: " + e.getMessage());

} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "C";

if (nomeCoordenador != null && nomeCoordenador.trim().length() > 0) {
    letraAvatar = nomeCoordenador.substring(0, 1).toUpperCase();
}

String sucesso = request.getParameter("sucesso");
String erro = request.getParameter("erro");
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Meu Perfil - Coordenador</title>
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
            <a href="coordenador.jsp">Dashboard</a>
            <a href="disciplinas.jsp">Minhas Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="gestao_inscricoes.jsp">Gestão de Inscrições</a>
            <a href="perfil.jsp" class="active">Meu Perfil</a>
        </nav>

        <div class="logout-area">
            <a href="<%= request.getContextPath() %>/paginas/logout.jsp" class="logout-btn">
                Terminar sessão
            </a>
        </div>

    </aside>

    <main class="main-content">

        <header class="topbar">

            <div class="search-box">
                <input type="text" placeholder="Meu perfil" disabled>
            </div>

            <div class="topbar-right">
                <div class="user-box">

                    <div class="user-avatar">
                        <%= letraAvatar %>
                    </div>

                    <div class="user-info">
                        <strong><%= nomeCoordenador %></strong>
                        <span>Coordenador</span>
                    </div>

                </div>
            </div>

        </header>

        <section class="page-header">
            <h1>Meu Perfil</h1>
            <p>
                Consulta e atualiza os teus dados pessoais de coordenador.
            </p>
        </section>

        <section class="profile-section">

            <div class="profile-card">

                <div class="crud-header">
                    <h2>Coordenador</h2>
                </div>

                <%
                    if ("perfil_atualizado".equals(sucesso)) {
                %>
                    <div class="alert-sucesso">
                        Perfil atualizado com sucesso.
                    </div>
                <%
                    }

                    if ("campos_obrigatorios".equals(erro)) {
                %>
                    <div class="alert-erro">
                        Preenche os campos obrigatórios.
                    </div>
                <%
                    }

                    if ("email_existente".equals(erro)) {
                %>
                    <div class="alert-erro">
                        Este email já está associado a outro utilizador.
                    </div>
                <%
                    }
                %>

                <form action="perfil_atualizar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome</label>
                            <input 
                                type="text" 
                                name="nome" 
                                value="<%= nomeCoordenador %>" 
                                required
                            >
                        </div>

                        <div class="form-group">
                            <label>Email</label>
                            <input 
                                type="email" 
                                name="email" 
                                value="<%= emailCoordenador %>" 
                                required
                            >
                        </div>

                        <div class="form-group">
                            <label>Curso</label>
                            <input 
                                type="text" 
                                name="curso" 
                                value="<%= cursoCoordenador %>" 
                                required
                            >
                        </div>

                        <div class="form-group">
                            <label>Nova palavra-passe</label>
                            <input 
                                type="password" 
                                name="password" 
                                placeholder="Deixa vazio se não quiseres alterar"
                            >
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="coordenador.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Perfil
                        </button>
                    </div>

                </form>

            </div>

        </section>

    </main>

</div>

</body>
</html>