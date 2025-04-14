🛡️ Lab: Detecting Unauthorized System Behavior with Falco

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 10–15 minutes

🎯 Goal:  
One of the deployed pods is trying to alter critical system files. Another is installing new software — both are suspicious behaviors.

📌 Your mission:
1. Use Falco (already installed) to identify which pods are exhibiting unusual behavior.
2. Investigate their logs and detect:
   - One pod writing to /etc/shadow
   - One pod running a package manager
3. Scale the corresponding deployments to 0 to neutralize the threats.

🧰 Context:
- Three namespaces are created: `team-green`, `team-blue`, `team-red`.
- Three applications are deployed. Two are misbehaving.
- Falco is installed but **not running as a service**. You must launch it manually

✅ Expected result:

- The two suspicious deployments are scaled down to 0.
- The third deployment remains unaffected.