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

int userId = Integer.parseInt(userIdObj.toString());

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeAdmin = "";
String emailAdmin = "";
String perfilAdmin = "";
int ativo = 1;
String criadoEm = "";
String atualizadoEm = "";

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT nome, email, perfil, ativo, " +
        "DATE_FORMAT(criado_em, '%d/%m/%Y %H:%i') AS criado_em, " +
        "DATE_FORMAT(atualizado_em, '%d/%m/%Y %H:%i') AS atualizado_em " +
        "FROM utilizadores " +
        "WHERE id = ? AND perfil = 'ADMINISTRADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        nomeAdmin = rs.getString("nome");
        emailAdmin = rs.getString("email");
        perfilAdmin = rs.getString("perfil");
        ativo = rs.getInt("ativo");
        criadoEm = rs.getString("criado_em");
        atualizadoEm = rs.getString("atualizado_em");
    } else {
        response.sendRedirect(request.getContextPath() + "/paginas/index.jsp?erro=admin_nao_encontrado");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar perfil: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "A";

if (nomeAdmin != null && nomeAdmin.trim().length() > 0) {
    letraAvatar = nomeAdmin.substring(0, 1).toUpperCase();
}

String estadoTexto = ativo == 1 ? "Ativo" : "Inativo";
String estadoClasse = ativo == 1 ? "estado-ativo" : "estado-inativo";
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Meu Perfil - Gesturma</title>
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
            <a href="utilizadores.jsp">Gestão Utilizadores</a>
            <a href="disciplinas.jsp">Gestão de Disciplinas</a>
            <a href="turmas.jsp">Gestão de Turmas</a>
            <a href="inscricoes.jsp">Gestão de Inscrições</a>

            <a href="perfil.jsp" class="active">
                Meu Perfil
            </a>
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
                    <div class="user-avatar"><%= letraAvatar %></div>

                    <div class="user-info">
                        <strong><%= nomeAdmin %></strong>
                        <span>Administrador</span>
                    </div>
                </div>
            </div>
        </header>

        <section class="page-header">
            <h1>Meu Perfil</h1>
            <p>Consulta e atualiza os teus dados de administrador.</p>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <h2>Dados do Administrador</h2>

                <div class="profile-grid">

                    <div class="profile-item">
                        <span>Nome completo</span>
                        <strong><%= nomeAdmin %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Email</span>
                        <strong><%= emailAdmin %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Perfil</span>
                        <strong><%= perfilAdmin %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Estado</span>
                        <strong>
                            <span class="<%= estadoClasse %>">
                                <%= estadoTexto %>
                            </span>
                        </strong>
                    </div>

                    <div class="profile-item">
                        <span>Criado em</span>
                        <strong><%= criadoEm %></strong>
                    </div>

                    <div class="profile-item">
                        <span>Atualizado em</span>
                        <strong><%= atualizadoEm %></strong>
                    </div>

                </div>

            </div>
        </section>

        <section class="profile-section">
            <div class="profile-card">

                <h2>Editar Perfil</h2>

                <form action="perfil_atualizar.jsp" method="post" class="crud-form">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Nome completo</label>
                            <input type="text" name="nome" value="<%= nomeAdmin %>" required>
                        </div>

                        <div class="form-group">
                            <label>Email</label>
                            <input type="email" name="email" value="<%= emailAdmin %>" required>
                        </div>

                        <div class="form-group">
                            <label>Nova password</label>
                            <input type="password" name="password" placeholder="Deixa vazio para manter a atual">
                        </div>

                        <div class="form-group">
                            <label>Perfil</label>
                            <input type="text" value="Administrador" disabled>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="admin.jsp" class="btn-voltar">
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