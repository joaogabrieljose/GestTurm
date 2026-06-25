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

String idParam = request.getParameter("id");

if (idParam == null || idParam.trim().isEmpty()) {
    response.sendRedirect("estados.jsp?erro=id_invalido");
    return;
}

int userId = Integer.parseInt(userIdObj.toString());
int inscricaoId = Integer.parseInt(idParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String nomeCoordenador = "";
String alunoNome = "";
String disciplinaNome = "";
String disciplinaCodigo = "";
String estadoAtual = "";
int turmaIdAtual = 0;

try {
    con = dbConnect();

    /*
        Buscar a inscrição, mas apenas se ela pertencer
        a uma disciplina do coordenador autenticado.
    */
    ps = con.prepareStatement(
        "SELECT " +
        "i.id, " +
        "i.estado, " +
        "i.turma_id, " +
        "u.nome AS aluno_nome, " +
        "d.nome AS disciplina, " +
        "d.codigo AS codigo_disciplina, " +
        "uc.nome AS coordenador_nome " +
        "FROM inscricoes i " +
        "INNER JOIN alunos a ON a.id = i.aluno_id " +
        "INNER JOIN utilizadores u ON u.id = a.utilizador_id " +
        "INNER JOIN disciplinas d ON d.id = i.disciplina_id " +
        "INNER JOIN coordenadores c ON c.id = d.coordenador_id " +
        "INNER JOIN utilizadores uc ON uc.id = c.utilizador_id " +
        "WHERE i.id = ? " +
        "AND uc.id = ? " +
        "AND uc.perfil = 'COORDENADOR' " +
        "LIMIT 1"
    );

    ps.setInt(1, inscricaoId);
    ps.setInt(2, userId);
    rs = dbQuery(con, ps);

    if (rs.next()) {
        alunoNome = rs.getString("aluno_nome");
        disciplinaNome = rs.getString("disciplina");
        disciplinaCodigo = rs.getString("codigo_disciplina");
        estadoAtual = rs.getString("estado");
        turmaIdAtual = rs.getInt("turma_id");
        nomeCoordenador = rs.getString("coordenador_nome");
    } else {
        response.sendRedirect("estados.jsp?erro=inscricao_nao_permitida");
        return;
    }

} catch (Exception e) {
    out.print("Erro ao carregar inscrição: " + e.getMessage());
} finally {
    dbClose(rs, ps, con);
}

String letraAvatar = "C";

if (nomeCoordenador != null && nomeCoordenador.trim().length() > 0) {
    letraAvatar = nomeCoordenador.substring(0, 1).toUpperCase();
}
%>

<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <title>Editar Estado da Inscrição - Gesturma</title>
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
            <a href="gestao_inscricoes.jsp" class="active">Gestão de Inscrições</a>
            <a href="perfil.jsp">Meu Perfil</a>
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
                <input type="text" placeholder="Editar estado da inscrição" disabled>
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
            <h1>Editar Estado</h1>
            <p>
                Atualiza apenas o estado da inscrição selecionada.
            </p>
        </section>

        <section class="profile-section">

            <div class="profile-card">

               <form action="estado_atualizar.jsp" method="post" class="crud-form">

                    <input type="hidden" name="id" value="<%= inscricaoId %>">

                    <div class="form-grid">

                        <div class="form-group">
                            <label>Aluno</label>
                            <input 
                                type="text" 
                                value="<%= alunoNome %>" 
                                disabled
                            >
                        </div>

                        <div class="form-group">
                            <label>Disciplina</label>
                            <input 
                                type="text" 
                                value="<%= disciplinaNome %> (<%= disciplinaCodigo %>)" 
                                disabled
                            >
                        </div>

                        <div class="form-group">
                            <label>Estado</label>
                            <select name="estado" required>
                                <option value="ATIVA" <%= "ATIVA".equalsIgnoreCase(estadoAtual) ? "selected" : "" %>>
                                    Ativa
                                </option>

                                <option value="ALTERADA" <%= "ALTERADA".equalsIgnoreCase(estadoAtual) ? "selected" : "" %>>
                                    Alterada
                                </option>

                                <option value="CANCELADA" <%= "CANCELADA".equalsIgnoreCase(estadoAtual) ? "selected" : "" %>>
                                    Cancelada
                                </option>
                            </select>
                        </div>

                    </div>

                    <div class="form-actions">
                        <a href="estados.jsp" class="btn-voltar">
                            Voltar
                        </a>

                        <button type="submit" class="crud-btn">
                            Atualizar Estado
                        </button>
                    </div>

                </form>

            </div>

        </section>

    </main>

</div>

</body>
</html>