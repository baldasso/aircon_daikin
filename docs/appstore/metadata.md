# App Store metadata

Everything App Store Connect asks for, in both languages. Character limits are Apple's.

## Shared

| Field | Value |
|---|---|
| Bundle ID | `dev.baldasso.aircon` |
| SKU | `aircon-mac-1` |
| Primary category | Utilities |
| Secondary category | Lifestyle |
| Price | Free (or set one; nothing in the app depends on it) |
| Age rating | 4+ (answer "None" to every content question) |
| Copyright | © 2026 Matheus Baldasso |
| Support URL | https://baldasso.github.io/aircon_daikin/support |
| Privacy policy URL | https://baldasso.github.io/aircon_daikin/privacy |
| Marketing URL | https://github.com/baldasso/aircon_daikin |
| Privacy "nutrition label" | **Data Not Collected** |

## English (U.S.) — primary

**Name** (30): `Aircon for Daikin`

**Subtitle** (30): `Your AC in the Mac menu bar`

**Keywords** (100):
```
daikin,air conditioner,ac,ecoswing,smart ac,split,climate,temperature,cooling,thermostat,remote
```

**Promotional text** (170):
> Control every Daikin Smart AC unit in your home from the menu bar: power, temperature, mode, fan and swing, all over your own Wi-Fi.

**Description** (4000):
> Aircon puts your Daikin air conditioners in the Mac menu bar. One click shows every room; one drag sets the temperature.
>
> Built for the Daikin units set up with the Daikin Smart AC app (EcoSwing Smart and compatible models).
>
> AT A GLANCE
> • A tab per room, with a lit dot when that unit is running
> • Each unit's current state and the room temperature
> • An animated unit that opens its flap and shows the airflow, so you can tell it's running from across the room
>
> CONTROL
> • Turn units on and off
> • Drag to set the temperature, or use the arrow keys
> • Cool, dry, fan and auto (and heat, on units that have it)
> • Fan speed 1–5, auto or quiet
> • Swing, eco and powerful modes
>
> PRIVATE BY DESIGN
> • Talks to your units directly over your Wi-Fi: no account, no cloud, no tracking
> • Device keys are kept in your Mac's keychain
> • Uses almost no energy: with the panel closed it checks in every two minutes and otherwise sleeps
>
> SETUP IN A MINUTE
> Aircon finds the units on your network. For each one, copy its device key from the Daikin Smart AC app (Menu → Integrations → Home Assistant) and paste it in. Aircon checks the key with the unit straight away, and fixes the usual copying mix-ups like I and l.
>
> Not sure yet? Try the demo, no air conditioner needed.
>
> Aircon is an independent app. It is not affiliated with, endorsed by or sponsored by Daikin. Daikin is a trademark of Daikin Industries, Ltd.

**What's new** (first version): `First release.`

## Portuguese (Brazil)

**Name** (30): `Aircon para Daikin`

**Subtitle** (30): `Seu ar-condicionado no Mac`

**Keywords** (100):
```
daikin,ar condicionado,ecoswing,smart ac,split,climatizador,temperatura,controle,termostato,frio
```

**Promotional text** (170):
> Controle todos os aparelhos Daikin Smart AC da casa pela barra de menus: liga e desliga, temperatura, modo, ventilação e oscilação, tudo pela sua rede Wi-Fi.

**Description** (4000):
> O Aircon coloca seus ares-condicionados Daikin na barra de menus do Mac. Um clique mostra todos os cômodos; um gesto ajusta a temperatura.
>
> Feito para os aparelhos Daikin configurados com o app Daikin Smart AC (EcoSwing Smart e modelos compatíveis).
>
> DE RELANCE
> • Uma aba por cômodo, com um ponto aceso quando o aparelho está ligado
> • O estado de cada aparelho e a temperatura do ambiente
> • Uma unidade animada que abre a aleta e mostra o fluxo de ar, para você saber de longe que está ligado
>
> CONTROLE
> • Liga e desliga
> • Arraste para ajustar a temperatura, ou use as setas do teclado
> • Resfriar, secar, ventilar e automático (e aquecer, nos aparelhos que têm)
> • Ventilação de 1 a 5, automática ou silenciosa
> • Oscilação, modo econômico e turbo
>
> PRIVACIDADE DE VERDADE
> • Conversa direto com os aparelhos pela sua rede Wi-Fi: sem conta, sem nuvem, sem rastreamento
> • As chaves dos aparelhos ficam no Keychain do Mac
> • Quase não gasta energia: com o painel fechado, consulta os aparelhos a cada dois minutos e fica em repouso
>
> CONFIGURAÇÃO EM UM MINUTO
> O Aircon encontra os aparelhos na sua rede. Para cada um, copie a chave do dispositivo no app Daikin Smart AC (Menu → Integração HA) e cole no Aircon. Ele testa a chave na hora e corrige as confusões comuns de cópia, como I e l.
>
> Quer conhecer antes? Veja a demonstração, sem precisar de ar-condicionado.
>
> O Aircon é um app independente, sem vínculo, aprovação ou patrocínio da Daikin. Daikin é marca registrada da Daikin Industries, Ltd.

**Novidades** (primeira versão): `Primeira versão.`

## App Review notes

Paste into "Notes" under App Review Information:

> Aircon controls Daikin air conditioners (the Brazilian Daikin Smart AC line) over the local network. Reviewing it with real hardware needs one of those units on the same Wi-Fi, so the app includes a demo:
>
> 1. Launch Aircon. It lives in the menu bar (air conditioner icon, top right); there is no Dock icon.
> 2. Click the icon, then "Try a demo".
> 3. Three pretend rooms appear. Everything works as it does with real units: turn them on and off, drag the large temperature up or down, change mode, fan and swing.
> 4. "Demo ×" at the top leaves the demo.
>
> The app asks for Local Network access because it talks to the units directly on the user's Wi-Fi (HTTP on port 15914, encrypted with each unit's key). It collects no data and has no server or account.
>
> The name says "for Daikin" only to describe compatibility; the app and its listing state that it is not affiliated with Daikin.

No sign-in is needed, so leave the demo account fields empty.

## Export compliance

App Store Connect asks about encryption on upload. Aircon encrypts its messages to the air conditioner with AES-128 (Apple's CommonCrypto), because the unit's protocol requires it. It has no other encryption of its own. Answer the questionnaire with that in mind; the answer is a legal declaration, so it is yours to make. Once you have it, `ITSAppUsesNonExemptEncryption` can be added to the Info.plist (`project.yml`) so the question isn't asked on every upload.
