<b>dice (Dice Pro Simulator)</b><br>
![diceIcon1024](https://user-images.githubusercontent.com/51520928/113064310-9dce4000-916b-11eb-9263-33a2c59ed35c.png)

dice is an iOS application (called "Dice Pro Simulator" on App Store) that uses SceneKit to do the physics of rolling various dice: coins, d4, d6, d8, d10, d12 and d20. 

Tapping, swiping and curly swiping on the Table drops, throws and spin dice. One can also assign "actions" for tapping, double tapping, triple tapping, long tapping and pinching individual die.

One can set the size of the dice, the default throwing strength, if held/selected die should pulse, the number of undo and keeping track of throw history.

It also includes a few dice games. Works well on either iPhone or iPad.


Binaries can be found at:<br>

  https://entonos.com/index.php/the-geek-shop/ <br>


## Installing the `.ipa` (iOS / iPadOS)

Because Apple requires apps installed outside the App Store to be signed for your device, you cannot install the `.ipa` file simply by tapping it in the Files app. Instead, use one of the free methods below to sign and install it with your own Apple ID:

### Option 1: Using a Mac (Xcode — Easiest if you have a Mac)
1. Download the `.ipa` file from the **Releases** page.
2. Connect your iPad or iPhone to your Mac via USB and unlock it.
3. Open **Xcode** and press **Shift + Command + 2** (`⇧⌘2`) to open **Devices and Simulators**.
4. Select your device in the left sidebar.
5. Drag and drop the `.ipa` file into the **Installed Apps** section (or click the `+` button under Installed Apps and select the `.ipa`).

### Option 2: Using a Mac or Windows PC (Sideloadly)
1. Download and install [Sideloadly](https://sideloadly.io) on your Mac or Windows PC.
2. Connect your iPad or iPhone via USB (and trust the computer if prompted).
3. Drag the `.ipa` file into Sideloadly, enter your Apple ID, and click **Start**.

### Option 3: On-Device Refreshing (AltStore / SideStore)
If you use [AltStore](https://altstore.io) or [SideStore](https://sidestore.io):
1. Download the `.ipa` file directly on your iPad or iPhone.
2. Open AltStore or SideStore, go to the **My Apps** tab, tap **`+`**, and select the downloaded `.ipa`.
*(Tip: AltStore and SideStore can automatically refresh the app signature over Wi-Fi so it doesn't expire after 7 days.)*

---

### First-Time Launch (Trusting Your Certificate)
The first time you install a self-signed app, iOS/iPadOS will show an **"Untrusted Developer"** message:
1. Open **Settings > General > VPN & Device Management**.
2. Tap your Apple ID under **Developer App** and tap **Trust**.
3. On iOS/iPadOS 16+, you may also need to enable **Developer Mode** under **Settings > Privacy & Security > Developer Mode**.

> **Note on Expiration:** Apps signed with a standard free Apple ID remain valid for **7 days** before needing to be re-signed (unless refreshed automatically via AltStore/SideStore). Apps signed with a paid Apple Developer account last **1 year**.
