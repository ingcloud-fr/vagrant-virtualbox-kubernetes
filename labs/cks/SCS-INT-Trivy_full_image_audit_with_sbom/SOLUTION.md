# ✅ Solution – Secure Image & SBOM Management with Trivy

## 🛠️ Tools in Use

- **Trivy CLI version**: <!-- fill version -->
- **Docker version**: <!-- fill version -->
- **Base image used**: `python:3.9-slim` (initial) ➔ replaced by `...` (final)

## Notes

Normaly, the vagrant user is added to the docker group inorder to avoid `sudo docker ...` or `sudo trivy ...`

If not :

```
$ sudo usermod -aG docker vagrant
```

+ deconnect reconnet

## 🔨 Step 1 – Build the Initial Image with Docker

```
$ cd demo-app/

$ docker build -t demo-app .

$ docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
demo-app     latest    c9211390bb61   25 seconds ago   126MB

```

✅ The image is successfully built and tagged.

---

## 🔍 Step 2 – Scan the Image for Vulnerabilities

```bash
$ trivy image demo-app
2025-04-18T06:18:43Z	INFO	[vulndb] Need to update DB
2025-04-18T06:18:43Z	INFO	[vulndb] Downloading vulnerability DB...
2025-04-18T06:18:43Z	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
62.39 MiB / 62.39 MiB [------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00% 3.23 MiB p/s 20s
2025-04-18T06:19:03Z	INFO	[vulndb] Artifact successfully downloaded	repo="mirror.gcr.io/aquasec/trivy-db:2"
2025-04-18T06:19:03Z	INFO	[vuln] Vulnerability scanning is enabled
2025-04-18T06:19:03Z	INFO	[secret] Secret scanning is enabled
2025-04-18T06:19:03Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2025-04-18T06:19:03Z	INFO	[secret] Please see also https://trivy.dev/v0.61/docs/scanner/secret#recommendation for faster secret detection
2025-04-18T06:19:13Z	INFO	[python] Licenses acquired from one or more METADATA files may be subject to additional terms. Use `--debug` flag to see all affected packages.
2025-04-18T06:19:14Z	INFO	Detected OS	family="debian" version="12.10"
2025-04-18T06:19:14Z	INFO	[debian] Detecting vulnerabilities...	os_version="12" pkg_num=105
2025-04-18T06:19:14Z	INFO	Number of language-specific files	num=1
2025-04-18T06:19:14Z	INFO	[python-pkg] Detecting vulnerabilities...
2025-04-18T06:19:14Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/v0.61/docs/scanner/vulnerability#severity-selection for details.
2025-04-18T06:19:14Z	INFO	Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Report Summary

┌────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                   Target                                   │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ demo-app (debian 12.10)                                                    │   debian   │       105       │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/pip-23.0.1.dist-info/METADATA        │ python-pkg │        1        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/setuptools-58.1.0.dist-info/METADATA │ python-pkg │        2        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/wheel-0.45.1.dist-info/METADATA      │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

...
```

📌 **Findings**:
- Total vulnerabilities found: `XX`
- High/Critical: `X High`, `Y Critical`
- Notable CVEs: `...`

---

## 📊 Step 3 – Filter and Analyze Vulnerabilities

```bash
$ trivy image --severity HIGH,CRITICAL demo-app
$ trivy image --severity HIGH,CRITICAL demo-app
2025-04-18T06:26:27Z	INFO	[vuln] Vulnerability scanning is enabled
2025-04-18T06:26:27Z	INFO	[secret] Secret scanning is enabled
2025-04-18T06:26:27Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2025-04-18T06:26:27Z	INFO	[secret] Please see also https://trivy.dev/v0.61/docs/scanner/secret#recommendation for faster secret detection
2025-04-18T06:26:27Z	INFO	Detected OS	family="debian" version="12.10"
2025-04-18T06:26:27Z	INFO	[debian] Detecting vulnerabilities...	os_version="12" pkg_num=105
2025-04-18T06:26:27Z	INFO	Number of language-specific files	num=1
2025-04-18T06:26:27Z	INFO	[python-pkg] Detecting vulnerabilities...
2025-04-18T06:26:27Z	WARN	Using severities from other vendors for some vulnerabilities. Read https://trivy.dev/v0.61/docs/scanner/vulnerability#severity-selection for details.
2025-04-18T06:26:27Z	INFO	Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Report Summary

┌────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                   Target                                   │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ demo-app (debian 12.10)                                                    │   debian   │        2        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/pip-23.0.1.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/setuptools-58.1.0.dist-info/METADATA │ python-pkg │        2        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/wheel-0.45.1.dist-info/METADATA      │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


demo-app (debian 12.10)

Total: 2 (HIGH: 1, CRITICAL: 1)

┌───────────┬────────────────┬──────────┬──────────────┬───────────────────┬───────────────┬────────────────────────────────────────────────────────┐
│  Library  │ Vulnerability  │ Severity │    Status    │ Installed Version │ Fixed Version │                         Title                          │
├───────────┼────────────────┼──────────┼──────────────┼───────────────────┼───────────────┼────────────────────────────────────────────────────────┤
│ perl-base │ CVE-2023-31484 │ HIGH     │ affected     │ 5.36.0-7+deb12u1  │               │ perl: CPAN.pm does not verify TLS certificates when    │
│           │                │          │              │                   │               │ downloading distributions over HTTPS...                │
│           │                │          │              │                   │               │ https://avd.aquasec.com/nvd/cve-2023-31484             │
├───────────┼────────────────┼──────────┼──────────────┼───────────────────┼───────────────┼────────────────────────────────────────────────────────┤
│ zlib1g    │ CVE-2023-45853 │ CRITICAL │ will_not_fix │ 1:1.2.13.dfsg-1   │               │ zlib: integer overflow and resultant heap-based buffer │
│           │                │          │              │                   │               │ overflow in zipOpenNewFileInZip4_6                     │
│           │                │          │              │                   │               │ https://avd.aquasec.com/nvd/cve-2023-45853             │
└───────────┴────────────────┴──────────┴──────────────┴───────────────────┴───────────────┴────────────────────────────────────────────────────────┘

Python (python-pkg)

Total: 2 (HIGH: 2, CRITICAL: 0)

┌───────────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬───────────────────────────────────────────────────────┐
│        Library        │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                         Title                         │
├───────────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼───────────────────────────────────────────────────────┤
│ setuptools (METADATA) │ CVE-2022-40897 │ HIGH     │ fixed  │ 58.1.0            │ 65.5.1        │ pypa-setuptools: Regular Expression Denial of Service │
│                       │                │          │        │                   │               │ (ReDoS) in package_index.py                           │
│                       │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2022-40897            │
│                       ├────────────────┤          │        │                   ├───────────────┼───────────────────────────────────────────────────────┤
│                       │ CVE-2024-6345  │          │        │                   │ 70.0.0        │ pypa/setuptools: Remote code execution via download   │
│                       │                │          │        │                   │               │ functions in the package_index module in...           │
│                       │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-6345             │
└───────────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴───────────────────────────────────────────────────────┘

```

🎯 Observations:
- Critical vulnerability in `glibc`
- Base image `python:3.9-slim` contributes to many CVEs

---

## 🛡️ Step 4 – Rebuild Image with a Safer Base

Let's check the others images :

```
$ trivy image --severity HIGH,CRITICAL python:3.9-alpine
...
Report Summary

┌────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                                   Target                                   │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ python:3.9-alpine (alpine 3.21.3)                                          │   alpine   │        0        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/pip-23.0.1.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/setuptools-58.1.0.dist-info/METADATA │ python-pkg │        2        │    -    │
├────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ usr/local/lib/python3.9/site-packages/wheel-0.45.1.dist-info/METADATA      │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

Python (python-pkg)

Total: 2 (HIGH: 2, CRITICAL: 0)

┌───────────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬───────────────────────────────────────────────────────┐
│        Library        │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                         Title                         │
├───────────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼───────────────────────────────────────────────────────┤
│ setuptools (METADATA) │ CVE-2022-40897 │ HIGH     │ fixed  │ 58.1.0            │ 65.5.1        │ pypa-setuptools: Regular Expression Denial of Service │
│                       │                │          │        │                   │               │ (ReDoS) in package_index.py                           │
│                       │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2022-40897            │
│                       ├────────────────┤          │        │                   ├───────────────┼───────────────────────────────────────────────────────┤
│                       │ CVE-2024-6345  │          │        │                   │ 70.0.0        │ pypa/setuptools: Remote code execution via download   │
│                       │                │          │        │                   │               │ functions in the package_index module in...           │
│                       │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-6345             │
└───────────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴───────────────────────────────────────────────────────┘
```

```
$ trivy image --severity HIGH,CRITICAL gcr.io/distroless/python3
...
Report Summary

┌──────────────────────────────────────────┬────────┬─────────────────┬─────────┐
│                  Target                  │  Type  │ Vulnerabilities │ Secrets │
├──────────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ gcr.io/distroless/python3 (debian 12.10) │ debian │        3        │    -    │
└──────────────────────────────────────────┴────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

gcr.io/distroless/python3 (debian 12.10)

Total: 3 (HIGH: 2, CRITICAL: 1)

┌───────────┬────────────────┬──────────┬──────────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
│  Library  │ Vulnerability  │ Severity │    Status    │ Installed Version │ Fixed Version │                            Title                            │
├───────────┼────────────────┼──────────┼──────────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ libexpat1 │ CVE-2023-52425 │ HIGH     │ affected     │ 2.5.0-1+deb12u1   │               │ expat: parsing large tokens can trigger a denial of service │
│           │                │          │              │                   │               │ https://avd.aquasec.com/nvd/cve-2023-52425                  │
│           ├────────────────┤          ├──────────────┤                   ├───────────────┼─────────────────────────────────────────────────────────────┤
│           │ CVE-2024-8176  │          │ will_not_fix │                   │               │ libexpat: expat: Improper Restriction of XML Entity         │
│           │                │          │              │                   │               │ Expansion Depth in libexpat                                 │
│           │                │          │              │                   │               │ https://avd.aquasec.com/nvd/cve-2024-8176                   │
├───────────┼────────────────┼──────────┤              ├───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ zlib1g    │ CVE-2023-45853 │ CRITICAL │              │ 1:1.2.13.dfsg-1   │               │ zlib: integer overflow and resultant heap-based buffer      │
│           │                │          │              │                   │               │ overflow in zipOpenNewFileInZip4_6                          │
│           │                │          │              │                   │               │ https://avd.aquasec.com/nvd/cve-2023-45853                  │
└───────────┴────────────────┴──────────┴──────────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘

```
$ trivy image --severity HIGH,CRITICAL cgr.dev/chainguard/python:latest
...
Report Summary

┌───────────────────────────────────────────────────┬───────┬─────────────────┬─────────┐
│                      Target                       │ Type  │ Vulnerabilities │ Secrets │
├───────────────────────────────────────────────────┼───────┼─────────────────┼─────────┤
│ cgr.dev/chainguard/python:latest (wolfi 20230201) │ wolfi │        0        │    -    │
└───────────────────────────────────────────────────┴───────┴─────────────────┴─────────┘
```

We choose `cgr.dev/chainguard/python:latest`




✏️ We modified the `Dockerfile`:

```Dockerfile
FROM cgr.dev/chainguard/python:latest
COPY app.py /app.py
CMD ["python", "/app.py"]
```

```bash
docker build -t demo-app:secure .
```

```
$ docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED             SIZE
demo-app     secure    04cbb45a57cc   18 seconds ago      58.5MB
demo-app     latest    c9211390bb61   About an hour ago   126MB
```

✅ Image built using a hardened base image.

---

## 📦 Step 5 – Generate SBOM in CycloneDX format from Secure Image

```bash
trivy image --format cyclonedx --output sbom.json demo-app:secure
```

📝 SBOM saved as `sbom.json` in CycloneDX format.

---

## 🔎 Step 6 – Inspect SBOM Contents

```bash
cat sbom.json | jq .
```

📌 Dependencies:
- Python packages listed
- System libraries listed
- No obvious outdated/vulnerable components

---

## 🔁 Step 7 – Rescan the Image via SBOM

```
$ trivy sbom sbom.json
2025-04-18T07:47:25Z	INFO	[vuln] Vulnerability scanning is enabled
2025-04-18T07:47:25Z	INFO	Detected SBOM format	format="cyclonedx-json"
2025-04-18T07:47:25Z	INFO	Detected OS	family="wolfi" version="20230201"
2025-04-18T07:47:25Z	INFO	[wolfi] Detecting vulnerabilities...	pkg_num=23
2025-04-18T07:47:25Z	INFO	Number of language-specific files	num=0

Report Summary

┌────────────────────────────┬───────┬─────────────────┐
│           Target           │ Type  │ Vulnerabilities │
├────────────────────────────┼───────┼─────────────────┤
│ sbom.json (wolfi 20230201) │ wolfi │        0        │
└────────────────────────────┴───────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

✅ Result:
- `0 Critical`
- Remaining low/medium findings (optional to patch)
- Overall image posture significantly improved

---

## 📦 Step 8 – Scan the Saved Image Tarball


We save the image in a tar with Docker :

```
$ docker save demo-app:secure -o demo-app.tar
```

```
$ trivy image --input demo-app.tar
2025-04-18T07:48:05Z	INFO	[vuln] Vulnerability scanning is enabled
2025-04-18T07:48:05Z	INFO	[secret] Secret scanning is enabled
2025-04-18T07:48:05Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2025-04-18T07:48:05Z	INFO	[secret] Please see also https://trivy.dev/v0.61/docs/scanner/secret#recommendation for faster secret detection
2025-04-18T07:48:05Z	INFO	Detected OS	family="wolfi" version="20230201"
2025-04-18T07:48:05Z	INFO	[wolfi] Detecting vulnerabilities...	pkg_num=23
2025-04-18T07:48:05Z	INFO	Number of language-specific files	num=0

Report Summary

┌───────────────────────────────┬───────┬─────────────────┬─────────┐
│            Target             │ Type  │ Vulnerabilities │ Secrets │
├───────────────────────────────┼───────┼─────────────────┼─────────┤
│ demo-app.tar (wolfi 20230201) │ wolfi │        0        │    -    │
└───────────────────────────────┴───────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

```

📌 Scan from tarball works identically. Safe image confirmed.

---

## 🏁 Conclusion

✅ Vulnerabilities reduced from `X` to `Y`  
✅ Secure base image adopted  
✅ SBOM generated and verified  
✅ Best practices applied in image construction

