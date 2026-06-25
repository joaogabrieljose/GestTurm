<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../database/basedados.h" %>

<%
request.setCharacterEncoding("UTF-8");

String nome = request.getParameter("nome");
String email = request.getParameter("email");
String numeroAluno = request.getParameter("numero_aluno");
String curso = request.getParameter("curso");
String anoParam = request.getParameter("ano_curricular");
String password = request.getParameter("password");
String confirmarPassword = request.getParameter("confirmar_password");

if (
    nome == null || nome.trim().isEmpty() ||
    email == null || email.trim().isEmpty() ||
    numeroAluno == null || numeroAluno.trim().isEmpty() ||
    curso == null || curso.trim().isEmpty() ||
    anoParam == null || anoParam.trim().isEmpty() ||
    password == null || password.trim().isEmpty() ||
    confirmarPassword == null || confirmarPassword.trim().isEmpty()
) {
    response.sendRedirect("index.jsp?registo=campos_obrigatorios");
    return;
}

nome = nome.trim();
email = email.trim();
numeroAluno = numeroAluno.trim();
curso = curso.trim();
password = password.trim();
confirmarPassword = confirmarPassword.trim();

if (!password.equals(confirmarPassword)) {
    response.sendRedirect("index.jsp?registo=password_diferente");
    return;
}

int anoCurricular = 0;

try {
    anoCurricular = Integer.parseInt(anoParam);
} catch (Exception e) {
    response.sendRedirect("index.jsp?registo=ano_invalido");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total FROM utilizadores WHERE email = ?"
    );

    ps.setString(1, email);
    rs = dbQuery(con, ps);

    int emailExiste = 0;

    if (rs.next()) {
        emailExiste = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (emailExiste > 0) {
        response.sendRedirect("index.jsp?registo=email_existente");
        return;
    }

    ps = con.prepareStatement(
        "SELECT COUNT(*) AS total FROM alunos WHERE numero_aluno = ?"
    );

    ps.setString(1, numeroAluno);
    rs = dbQuery(con, ps);

    int numeroExiste = 0;

    if (rs.next()) {
        numeroExiste = rs.getInt("total");
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (numeroExiste > 0) {
        response.sendRedirect("index.jsp?registo=numero_existente");
        return;
    }

    con.setAutoCommit(false);

    ps = con.prepareStatement(
        "INSERT INTO utilizadores " +
        "(nome, email, password, perfil, ativo) " +
        "VALUES (?, ?, ?, 'ALUNO', 0)",
        Statement.RETURN_GENERATED_KEYS
    );

    ps.setString(1, nome);
    ps.setString(2, email);
    ps.setString(3, password);

    ps.executeUpdate();

    rs = ps.getGeneratedKeys();

    int utilizadorId = 0;

    if (rs.next()) {
        utilizadorId = rs.getInt(1);
    }

    dbClose(rs, ps, null);
    rs = null;
    ps = null;

    if (utilizadorId == 0) {
        con.rollback();
        response.sendRedirect("index.jsp?registo=erro");
        return;
    }

    ps = con.prepareStatement(
        "INSERT INTO alunos " +
        "(utilizador_id, numero_aluno, curso, ano_curricular) " +
        "VALUES (?, ?, ?, ?)"
    );

    ps.setInt(1, utilizadorId);
    ps.setString(2, numeroAluno);
    ps.setString(3, curso);
    ps.setInt(4, anoCurricular);

    ps.executeUpdate();

    con.commit();

    response.sendRedirect("index.jsp?registo=sucesso");
    return;

} catch (Exception e) {

    try {
        if (con != null) {
            con.rollback();
        }
    } catch (Exception ignored) {}

    out.print("<h2>Erro ao criar conta</h2>");
    out.print("<p>" + e.getMessage() + "</p>");
    out.print("<a href='index.jsp'>Voltar</a>");

} finally {
    try {
        if (con != null) {
            con.setAutoCommit(true);
        }
    } catch (Exception ignored) {}

    dbClose(rs, ps, con);
}
%>