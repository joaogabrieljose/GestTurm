<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    /*
      Obtém a sessão atual sem criar uma nova sessão.
    */
    jakarta.servlet.http.HttpSession sessaoAtual =
        request.getSession(false);

    /*
      Elimina todos os dados guardados na sessão,
      independentemente do perfil do utilizador.
    */
    if (sessaoAtual != null) {
        sessaoAtual.invalidate();
    }

    /*
      Redireciona para a página inicial.
      O request.getContextPath() evita problemas
      causados pelas diferentes pastas dos perfis.
    */
    response.sendRedirect(
        request.getContextPath() + "/paginas/index.jsp?logout=sucesso"
    );

    return;
%>