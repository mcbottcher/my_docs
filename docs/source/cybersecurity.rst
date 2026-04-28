Cybersecurity
=============

Overview
--------

**A certificate** is a digital document that shows something's identity and contains their public key.
It is signed by a trusted party (a CA) to say they have verified the identity of that thing.

**Signing** is using your private key to create proof that you created or approved something.
Anyone can verify the signature using your public key, proving it came from you without forging it.

----

Asymmetric Cryptography
-----------------------

Asymmetric cryptography uses a pair of mathematically linked keys: a **private key** and a **public key**.

**Key properties:**

- The public key can be freely shared; anyone can encrypt with it or verify a signature.
- The private key must never be shared; only the holder can decrypt messages or create signatures.
- A message encrypted with the public key can only be decrypted with the private key, and vice versa.
- These keys are derived from a mathematical relationship (typically modular exponentiation in RSA, or elliptic curve operations in ECDSA) such that knowing the public key does not reveal the private key.

**Common operations:**

- **Encryption**: encrypt with public key → send to private key holder → they decrypt with private key.
- **Signing**: private key holder signs data → anyone can verify the signature using the public key, proving the holder created it.
- **Key agreement**: two parties use each other's public keys to derive a shared secret without transmitting it (Diffie-Hellman, ECDH).

Asymmetric cryptography is slower than symmetric cryptography, so in practice it is often used to **exchange** a symmetric key, which then handles bulk data encryption.

----

TLS & Certificates
-------------------

Certificate Authorities (CAs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A CA is a trusted third party that vouches for the identity of a server or device.
Browsers and operating systems ship with a pre-installed list of trusted **root certificates**
(the root store), maintained by vendors such as Microsoft, Apple, Google and Mozilla.

A CA must pass rigorous audits (WebTrust, ETSI) to be included in a root store.

Certificate Structure (X.509)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Certificates follow the X.509 standard. Key fields::

    version            3
    serial_number      unique ID issued by CA
    subject            who the cert is for (CN, O, C)
    issuer             which CA signed it
    validity           not_before / not_after
    public_key         algorithm + key bytes
    extensions
      subject_alt_names   domains this cert is valid for
      key_usage           what the key may be used for
      is_ca               TRUE for CA certs, FALSE for leaf certs
      crl_url             where to check for revocation
    signature_algorithm  e.g. sha256WithRSAEncryption
    signature            CA's signed hash (see below)

Encoded on disk as **DER** (binary) or **PEM** (base64 wrapped in ``-----BEGIN CERTIFICATE-----``).

PEM & Certificate Files
^^^^^^^^^^^^^^^^^^^^^^^

**PEM encoding** is a text-based format: take binary data (DER), encode it as base64, and wrap it with a header and footer::

    -----BEGIN CERTIFICATE-----
    MIIDazCCAlOgAwIBAgIUI5g75HZUWvysQwCQEfCHSTUwDQYJKoZIhvcNAQELBQAw
    ... (base64 data)
    -----END CERTIFICATE-----

PEM is human-readable and can be viewed with ``cat`` or a text editor. Binary DER files cannot.

**Certificate files:**

- **.crt** — A signed certificate. Usually PEM encoded. Contains a public key + CA's signature proving the certificate is genuine.
- **.csr** — A Certificate Signing Request. PEM encoded. Bundles your public key with identity info (domain, organization, country). Signed by your private key to prove you own it. You send this to a CA, and they respond with a **.crt** file.

**How a CA verifies a CSR:**

When you send a CSR to a CA, the CA performs two checks:

1. **Cryptographic verification**: The CSR is signed with your private key. The CA verifies the signature using the public key in the CSR itself. This proves you own the private key corresponding to that public key — you cannot forge a CSR for someone else's key.
2. **Identity verification**: The CA checks the identity fields (domain, organization, etc.) in the CSR. For domain validation, they might verify you control the domain by sending an email to the registrant or checking a DNS record. For extended validation (EV), they perform more rigorous checks.

If both checks pass, the CA signs the CSR to produce a **.crt** file.

How a Certificate is Signed
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Signing is a two-step cryptographic operation performed by the CA:

1. **Hash** the certificate data with SHA-256 to produce a fixed-length fingerprint.
2. **Encrypt the hash** with the CA's private key. The result is the signature.

The signature is appended to the certificate data to form the final certificate.

**Verification** (performed by a browser or device):

1. Separate the signature from the certificate data.
2. Decrypt the signature using the CA's *public* key → recovers hash A.
3. Independently hash the certificate data → hash B.
4. If A == B the certificate is genuine and untampered.

Root Certificates
^^^^^^^^^^^^^^^^^

Root certificates are **self-signed** — the CA signs its own certificate with its own
private key. This is cryptographically circular and proves nothing on its own.
This is basically a way to store the CA's public key which you can use for verifying certificates signed
by the Certificate Authority.

Trust is established **out-of-band**: the certificate is physically placed on the machine
by the OS vendor or hardware manufacturer, before any network connection exists.

This is why you cannot fetch a root cert from a CA's website to bootstrap trust —
you have no trusted channel to retrieve it over, and the system would be circular.

Chain of Trust
^^^^^^^^^^^^^^

Root CAs rarely sign leaf certificates directly. A typical chain::

    Root CA  (pre-installed, private key kept offline in a vault)
        └── Intermediate CA  (signed by Root)
                └── Leaf certificate  (signed by Intermediate, installed on server)

This keeps the root CA private key offline. If an intermediate is compromised it can
be revoked without touching the root.

TLS Handshake (one-way)
^^^^^^^^^^^^^^^^^^^^^^^

In a TLS handshake, the client establishes a secure encrypted connection to the server:

1. **ClientHello**: Client initiates the connection, offering supported cipher suites and TLS versions.

2. **Server sends Certificate**: The server responds with its certificate, which contains:
   - The server's public key
   - Server identity (domain name, organization)
   - The CA's digital signature proving the certificate is genuine and can be trusted

3. **Client verifies the certificate**:
   - Checks that the CA's signature is valid (using the CA's public key from the root store)
   - Checks the certificate is not expired
   - Checks the certificate domain matches the server's hostname
   - If all checks pass, the client trusts the server's public key

4. **Establish encrypted session**: The client generates a random session key, encrypts it with the server's public key, and sends it.
   Only the server (holding the private key) can decrypt it. Both parties now share a session key to encrypt all further communication.

The diagram below shows the message flow::

    Client                          Server
      │  ClientHello               │
      │ ─────────────────────────► │
      │  Certificate               │
      │ ◄───────────────────────── │
      │                            │
      │  Verify: CA sig valid?     │
      │          Not expired?      │
      │          Domain matches?   │
      │                            │
      │ ◄──── Encrypted session ── │

Mutual TLS (mTLS)
^^^^^^^^^^^^^^^^^

Both parties present and verify certificates. Each side holds three items:

* **Root CA certificate** — used to verify the other side's certificate.
* **Device certificate** — presented to the other side (contains public key + CA signature).
* **Device private key** — never transmitted; used to prove ownership of the certificate.

During the handshake, both sides exchange certificates and challenge each other to prove ownership
of their private keys. Each side signs handshake data with its private key; the other side verifies
the signature using the public key in the certificate. This bidirectional verification proves both
sides genuinely hold their private keys and can be trusted.

**When to use mTLS**: In one-way TLS, only the server proves its identity; the server trusts any
client that can establish a connection. mTLS adds a second verification step so the server can
also verify the client's identity. This is essential in scenarios where:

- Devices need to authenticate to a service (not just the service authenticating to devices)
- The service must reject connections from unknown or revoked devices
- Both parties need proof that they're communicating with an authorized counterpart

----

Hardware Security & Device Provisioning
----------------------------------------

Secure Elements
^^^^^^^^^^^^^^^

A secure element (e.g. ATECC608) is a dedicated hardware chip that stores and uses
private keys without ever exposing them.

**Key generation**::

    Host MCU sends:   "generate key in slot N"
    Secure element:   generates private key internally
                      derives public key from private key
    Returns to MCU:   public key only

The public key can be freely exported because deriving it from the private key is a
one-way operation — it cannot be reversed.

**Signing**::

    Host MCU sends:   data + "sign with slot N"
    Secure element:   signs internally using private key
    Returns to MCU:   signature only

Typical secure elements have multiple key slots (ATECC608 has 16), which can be used
for different purposes (identity, firmware verification, data encryption, etc.).

Slots can be **locked** after provisioning so keys cannot be regenerated.

Device Provisioning
^^^^^^^^^^^^^^^^^^^

Devices typically run a **provisioning firmware** image once at the factory, then a
**production firmware** image in the field.

Provisioning sequence:

1. Factory flashes provisioning firmware.
2. Secure element generates private key in slot 0; returns public key to MCU.
3. MCU builds a CSR (public key + device identity).
4. CSR sent to provisioning server (typically over USB/UART).
5. Provisioning server signs CSR with the internal CA → device certificate.
6. Device stores: device certificate + root CA certificate in flash.
7. A one-time programmable (OTP) fuse is blown to mark device as provisioned.
8. Factory flashes production firmware.

The server only needs the root CA certificate. It does not need prior knowledge of
individual devices — any device presenting a valid certificate signed by the trusted
CA is accepted.

Secure Boot
^^^^^^^^^^^

The bootloader verifies firmware integrity before execution::

    Build time:
      FW image → SHA-256 → sign with vendor private key → signature

    Boot time:
      Bootloader hashes FW image
      Decrypts signature using vendor public key (stored in OTP fuses)
      If hashes match → boot
      If not          → halt / refuse to run

The vendor public key in OTP fuses is the hardware root of trust — it cannot be
modified after manufacture.

Integration with provisioning::

    OTP fuse: provisioned?
        NO  → run provisioning firmware
        YES → verify production firmware signature → run if valid

Chain of trust on the device::

    Hardware / OTP fuses
        └── Bootloader (hash baked into fuses)
                └── Production firmware (signature verified)
                        └── Server certificate (verified via root CA cert)
                                └── Server trusts device (via device cert verification)

Encrypted Firmware Updates
^^^^^^^^^^^^^^^^^^^^^^^^^^

Firmware images are typically both **signed** (integrity/authenticity) and **encrypted**
(IP protection). The usual pattern::

    FW image → encrypt with AES session key → sign encrypted blob with vendor private key

The AES session key itself is encrypted with a key stored in the secure element (hybrid
encryption), so the secure element only handles a small key operation rather than
decrypting the entire image.

Update verification on device:

1. Verify signature on encrypted blob using vendor public key in OTP.
2. Ask secure element to decrypt the session key.
3. Decrypt firmware image in chunks using session key.
4. Hash decrypted image and verify against expected hash.
5. Boot new firmware.

**Rollback protection** uses a monotonic counter in OTP fuses. The firmware header
declares a minimum version; the bootloader rejects any image below the fuse counter value.
After a successful boot the fuse counter is incremented. OTP fuses cannot be unburned,
so rollback is physically impossible.
