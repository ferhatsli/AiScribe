from autogen import UserProxyAgent

user_proxy = UserProxyAgent(
    name="user",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=0,
    code_execution_config=False,
    description="User agent representing the human user."
) 