# Local fonts

The app bundles fonts and never fetches them at runtime.

- Amiri Regular: https://github.com/google/fonts/tree/main/ofl/amiri
- Manrope: https://github.com/google/fonts/tree/main/ofl/manrope
- Licenses: `Amiri-OFL.txt` and `Manrope-OFL.txt` (SIL Open Font License 1.1).

`Manrope.ttf` is the upstream variable source. The Regular (400), SemiBold (600),
and Bold (700) instances were generated with fontTools 4.59.0 using
`instantiateVariableFont(font, {'wght': weight}, inplace=True, updateFontNames=True)`.
Static instances provide explicit weight matching in the project's Flutter SDK.
Only those instances and Amiri Regular are included in the application bundle.
