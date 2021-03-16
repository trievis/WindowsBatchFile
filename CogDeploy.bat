::Copy this File To Local Git Directory of Cog https://github.com/nedbat/cog then call from command prompt
git archive -o cog_v3.0.0.zip v3.0.0
::"C:\Program Files\7-Zip\7z" e -oV3.0.0 cog_v3.0.0.zip
"C:\Program Files\7-Zip\7z" x -oV3.0.0 cog_v3.0.0.zip
copy V3.0.0\scripts\cog.py V3.0.0\cog.py

