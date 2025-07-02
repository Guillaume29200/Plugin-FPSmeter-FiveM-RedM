<p>Want to measure your FiveM/RedM server performance using FPSMeter? Here’s a guide to install a small script that allows FPSMeter to retrieve the following data:</p>
<ol>
<li>✅ Real server FPS (tickrate)</li>
<li>✅ Number of connected players</li>
<li>✅ Average ping</li>
<li>✅ Uptime (server running time)</li>
</ol>
<br />
<p>⚠️ This script has no impact on performance, collects no sensitive data, and can be removed at any time.</p>

<h4>How to use ?</h4>
✅ Step 1: Add the resource to your server.cfg
<p></p>Create a folder in your server named fpsmeter_server Inside the folder, create the following two files:</p>
<ol>
<li>fxmanifest.lua</li>
<li>server.lua</li>
</ol>
<h4>✅ Step 2: Add the resource to your server.cfg</h4>
<p>Add the following line at the end of your server.cfg file:</p>
<pre>start fpsmeter_server</pre>
<p>Then restart your server.</p>
<h4>✅ Step 3: Configure your server’s RCON</h4>
<p>Make sure you have defined an RCON password in your server.cfg:</p>
<pre>rcon_password "votre_mot_de_passe_rcon"</code></pre>
<p>FPSMeter will connect securely using this password to run the fpsmeter command.</p>
<h4>✅ Step 4: Launch the analysis on FPSMeter</h4>
<p>Once your server is online:</p>
<ol>
<li>Go to https://fpsmeter.esport-cms.net/benchmark.php</li>
<li>Select FiveM from the list of games</li>
<li>Enter your server IP, RCON port and password</li>
<li>Start the analysis!</li>
</ol>
<p>⚠️ Your firewall must allow TCP RCON connections on your server port (usually 30120).</p>
