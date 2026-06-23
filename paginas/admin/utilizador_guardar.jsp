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

request.setCharacterEncoding("UTF-8");

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String password = request.getParameter("password");
String perfilNovo = request.getParameter("perfil");
String ativoParam = request.getParameter("ativo");

String numeroAluno = request.getParameter("numero_aluno");
String curso = request.getParameter("curso");
String anoParam = request.getParameter("ano_curricular");

if (
    nome == null || nome.trim().isEmpty() ||
    email == null || email.trim().isEmpty() ||
    password == null || password.trim().isEmpty() ||
    perfilNovo == null || perfilNovo.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty()
) {
    response.sendRedirect("utilizador_criar.jsp?erro=campos_obrigatorios");
    return;
}

int ativo = Integer.parseInt(ativoParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    ps = con.prepareStatement(
        "INSERT INTO utilizadores (nome, email, password, perfil, ativo) " +
        "VALUES (?, ?, ?, ?, ?)",
        Statement.RETURN_GENERATED_KEYS
    );

    ps.setString(1, nome.trim());
    ps.setString(2, email.trim());
    ps.setString(3, password.trim());
    ps.setString(4, perfilNovo.trim());
    ps.setInt(5, ativo);

    ps.executeUpdate();

    rs = ps.getGeneratedKeys();

    int utilizadorId = 0;

    if (rs.next()) {
        utilizadorId = rs.getInt(1);
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if ("ALUNO".equalsIgnoreCase(perfilNovo)) {

        if (
            numeroAluno == null || numeroAluno.trim().isEmpty() ||
            curso == null || curso.trim().isEmpty()
        ) {
            con.rollback();
            response.sendRedirect("utilizador_criar.jsp?erro=dados_aluno_obrigatorios");
            return;
        }

        int anoCurricular = 0;

        if (anoParam != null && !anoParam.trim().isEmpty()) {
            anoCurricular = Integer.parseInt(anoParam);
        }

        ps = con.prepareStatement(
            "INSERT INTO alunos (utilizador_id, numero_aluno, curso, ano_curricular) " +
            "VALUES (?, ?, ?, ?)"
        );

        ps.setInt(1, utilizadorId);
        ps.setString(2, numeroAluno.trim());
        ps.setString(3, curso.trim());

        if (anoCurricular > 0) {
            ps.setInt(4, anoCurricular);
        } else {
            ps.setNull(4, Types.INTEGER);
        }

        ps.executeUpdate();
    }

    if ("COORDENADOR".equalsIgnoreCase(perfilNovo)) {

        if (curso == null || curso.trim().isEmpty()) {
            con.rollback();
            response.sendRedirect("utilizador_criar.jsp?erro=curso_coordenador_obrigatorio");
            return;
        }

        ps = con.prepareStatement(
            "INSERT INTO coordenadores (utilizador_id, curso) " +
            "VALUES (?, ?)"
        );

        ps.setInt(1, utilizadorId);
        ps.setString(2, curso.trim());

        ps.executeUpdate();
    }

    con.commit();

    response.sendRedirect("utilizadores.jsp?sucesso=utilizador_criado");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    response.sendRedirect("utilizador_criar.jsp?erro=email_ou_numero_duplicado");
    return;

} catch (Exception e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    out.print("Erro ao guardar utilizador: " + e.getMessage());

} finally {

    if (con != null) {
        try { con.setAutoCommit(true); } catch (Exception ignored) {}
    }

    dbClose(rs, ps, con);
}
%>