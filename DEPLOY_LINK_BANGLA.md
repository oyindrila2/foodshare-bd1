# FoodShare BD — online link banano (Render, free)

1. github.com e account khulo -> "New repository" -> naam: foodshare-bd -> Create.
2. "uploading an existing file" e click koro -> ei folder er SHOB file/folder drag kore dao
   (render.yaml jeno main folder e thake) -> Commit changes.
3. render.com e jao -> "Sign in with GitHub".
4. New + -> Blueprint -> foodshare-bd repo select -> Apply.
5. 5-10 minute build hobe. Sesh hole link pabe: https://foodshare-bd-xxxx.onrender.com
6. Ei link kauke pathale she click korlei app khulbe.
   Demo login: donor@foodshare.bd / demo123

Mone rakhbe:
- Free plan e 15 minute keu na dhukle server ghumiye jay; porer bar khulte ~1 minute lage.
  Defense/demo er 5 minute age nije link ta ekbar khule rakho.
- Free plan e notun deploy/restart hole database (SQLite) o upload kora chobi muche jete pare.
  Demo data abar automatic chole ashbe. Sthayi data lagle Render e PostgreSQL database add kore
  DATABASE_URL set korte hobe.
