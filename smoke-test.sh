#!/usr/bin/env bash
# Runs inside the built image. Fails if anything the runner jobs rely on is missing.
set -euxo pipefail
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

dotnet --list-sdks
dotnet --list-sdks | grep -q '^10\.'
dotnet --list-sdks | grep -q '^11\.'
node --version
npm --version
git --version
ssh -V
zip -v | head -1
unzip -v | head -1
curl --version | head -1
jq --version

work="$(mktemp -d)"
cd "$work"

# .NET 11 SDK: build + run with ICU in use (culture-aware formatting needs libicu)
dotnet new console -n Smoke11 -o smoke11
cat > smoke11/Program.cs <<'CS'
var c = new System.Globalization.CultureInfo("de-DE");
System.Console.WriteLine(1234.5.ToString("N2", c));
CS
dotnet build smoke11 -p:InvariantGlobalization=false
dotnet run --project smoke11 --no-build | tee out11.txt
grep -q '1.234,50' out11.txt

# .NET 10 SDK, pinned via global.json so the 10.0 SDK itself is exercised
sdk10="$(dotnet --list-sdks | awk '/^10\./{v=$1} END{print v}')"
mkdir smoke10 && cd smoke10
dotnet new globaljson --sdk-version "$sdk10"
dotnet --version | grep -q '^10\.'
dotnet new console -n Smoke10 -o .
dotnet build -p:InvariantGlobalization=false
dotnet run --no-build

echo "SMOKE TEST PASSED"
