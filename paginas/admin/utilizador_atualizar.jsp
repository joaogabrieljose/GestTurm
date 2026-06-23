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

String idParam = request.getParameter("id");
String nome = request.getParameter("nome");
String email = request.getParameter("email");
String password = request.getParameter("password");
String perfilNovo = request.getParameter("perfil");
String ativoParam = request.getParameter("ativo");

String numeroAluno = request.getParameter("numero_aluno");
String curso = request.getParameter("curso");
String anoParam = request.getParameter("ano_curricular");

if (
    idParam == null || idParam.trim().isEmpty() ||
    nome == null || nome.trim().isEmpty() ||
    email == null || email.trim().isEmpty() ||
    perfilNovo == null || perfilNovo.trim().isEmpty() ||
    ativoParam == null || ativoParam.trim().isEmpty()
) {
    response.sendRedirect("utilizadores.jsp?erro=campos_obrigatorios");
    return;
}

int id = Integer.parseInt(idParam);
int ativo = Integer.parseInt(ativoParam);

Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = dbConnect();
    con.setAutoCommit(false);

    if (password != null && !password.trim().isEmpty()) {
        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ?, password = ?, perfil = ?, ativo = ? " +
            "WHERE id = ?"
        );

        ps.setString(1, nome.trim());
        ps.setString(2, email.trim());
        ps.setString(3, password.trim());
        ps.setString(4, perfilNovo.trim());
        ps.setInt(5, ativo);
        ps.setInt(6, id);

    } else {
        ps = con.prepareStatement(
            "UPDATE utilizadores " +
            "SET nome = ?, email = ?, perfil = ?, ativo = ? " +
            "WHERE id = ?"
        );

        ps.setString(1, nome.trim());
        ps.setString(2, email.trim());
        ps.setString(3, perfilNovo.trim());
        ps.setInt(4, ativo);
        ps.setInt(5, id);
    }

    ps.executeUpdate();
    dbClose(null, ps, null);
    ps = null;

    if ("ALUNO".equalsIgnoreCase(perfilNovo)) {

        if (
            numeroAluno == null || numeroAluno.trim().isEmpty() ||
            curso == null || curso.trim().isEmpty()
        ) {
            con.rollback();
            response.sendRedirect("utilizador_editar.jsp?id=" + id + "&erro=dados_aluno_obrigatorios");
            return;
        }

        int anoCurricular = 0;

        if (anoParam != null && !anoParam.trim().isEmpty()) {
            anoCurricular = Integer.parseInt(anoParam);
        }

        ps = con.prepareStatement(
            "DELETE FROM coordenadores WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        ps.executeUpdate();
        dbClose(null, ps, null);
        ps = null;

        ps = con.prepareStatement(
            "SELECT id FROM alunos WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        rs = dbQuery(con, ps);

        boolean existeAluno = rs.next();

        dbClose(rs, ps, null);
        rs = null;
        ps = null;

        if (existeAluno) {
            ps = con.prepareStatement(
                "UPDATE alunos " +
                "SET numero_aluno = ?, curso = ?, ano_curricular = ? " +
                "WHERE utilizador_id = ?"
            );

            ps.setString(1, numeroAluno.trim());
            ps.setString(2, curso.trim());

            if (anoCurricular > 0) {
                ps.setInt(3, anoCurricular);
            } else {
                ps.setNull(3, Types.INTEGER);
            }

            ps.setInt(4, id);
            ps.executeUpdate();

        } else {
            ps = con.prepareStatement(
                "INSERT INTO alunos (utilizador_id, numero_aluno, curso, ano_curricular) " +
                "VALUES (?, ?, ?, ?)"
            );

            ps.setInt(1, id);
            ps.setString(2, numeroAluno.trim());
            ps.setString(3, curso.trim());

            if (anoCurricular > 0) {
                ps.setInt(4, anoCurricular);
            } else {
                ps.setNull(4, Types.INTEGER);
            }

            ps.executeUpdate();
        }
    }

    if ("COORDENADOR".equalsIgnoreCase(perfilNovo)) {

        if (curso == null || curso.trim().isEmpty()) {
            con.rollback();
            response.sendRedirect("utilizador_editar.jsp?id=" + id + "&erro=curso_coordenador_obrigatorio");
            return;
        }

        ps = con.prepareStatement(
            "DELETE FROM alunos WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        ps.executeUpdate();
        dbClose(null, ps, null);
        ps = null;

        ps = con.prepareStatement(
            "SELECT id FROM coordenadores WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        rs = dbQuery(con, ps);

        boolean existeCoordenador = rs.next();

        dbClose(rs, ps, null);
        rs = null;
        ps = null;

        if (existeCoordenador) {
            ps = con.prepareStatement(
                "UPDATE coordenadores " +
                "SET curso = ? " +
                "WHERE utilizador_id = ?"
            );

            ps.setString(1, curso.trim());
            ps.setInt(2, id);
            ps.executeUpdate();

        } else {
            ps = con.prepareStatement(
                "INSERT INTO coordenadores (utilizador_id, curso) " +
                "VALUES (?, ?)"
            );

            ps.setInt(1, id);
            ps.setString(2, curso.trim());
            ps.executeUpdate();
        }
    }

    if ("ADMINISTRADOR".equalsIgnoreCase(perfilNovo)) {

        ps = con.prepareStatement(
            "DELETE FROM alunos WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        ps.executeUpdate();

        dbClose(null, ps, null);
        ps = null;

        ps = con.prepareStatement(
            "DELETE FROM coordenadores WHERE utilizador_id = ?"
        );
        ps.setInt(1, id);
        ps.executeUpdate();
    }

    con.commit();

    response.sendRedirect("utilizadores.jsp?sucesso=utilizador_atualizado");
    return;

} catch (SQLIntegrityConstraintViolationException e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    response.sendRedirect("utilizador_editar.jsp?id=" + id + "&erro=email_ou_numero_duplicado");
    return;

} catch (Exception e) {

    if (con != null) {
        try { con.rollback(); } catch (Exception ignored) {}
    }

    out.print("Erro ao atualizar utilizador: " + e.getMessage());

} finally {

    if (con != null) {
        try { con.setAutoCommit(true); } catch (Exception ignored) {}
    }

    dbClose(rs, ps, con);
}
%>