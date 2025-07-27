import functions_framework, json
from agent import chat_agent, verify_token

@functions_framework.http
def chat(request):
    id_token = request.headers.get("Authorization", "").split(" ").pop()
    uid = verify_token(id_token)
    body = request.get_json()
    msg = body.get("message")
    lang = body.get("lang", "en")
    answer = chat_agent.run(uid=uid, query=msg)
    return {"answer": answer, "lang": lang}, 200
