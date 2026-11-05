# People Bubble

A personal Android app (Flutter) for remembering what the people you care about like and
dislike. People and things are bubbles joined by styled lines, shown as a freeform canvas
and as a collapsible list.

- Product spec: [docs/People Bubble App — Plan.md](docs/People%20Bubble%20App%20—%20Plan.md)
- Working notes for contributors and agents: [CLAUDE.md](CLAUDE.md)

## Development

```bash
flutter pub get
dart run build_runner build   # regenerate drift code after editing tables
flutter test
flutter run
```
