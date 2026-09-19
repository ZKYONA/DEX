# Safe extraction/re-import demo

This folder gives you a controlled map to test ZK DEX export fidelity without extracting another creator's private place.

## Test procedure

1. Open a blank Baseplate in Roblox Studio.
2. Run `demo/GenerateDemoMap.server.lua` from the Command Bar or a temporary Script.
3. Use the ZK DEX Studio plugin's **Save Workspace Map**, or save the generated model.
4. Open/import the exported file in a fresh Studio place.
5. Run `demo/VerifyDemoMap.lua`.

The verifier checks:
- nested Models and Folders;
- Attributes;
- ObjectValue instance references;
- HingeConstraint Attachment0/Attachment1;
- Beam Attachment0/Attachment1;
- value objects;
- basic hierarchy fidelity.

This is intentionally a representative test harness, not an extraction method for a private experience you do not control.
