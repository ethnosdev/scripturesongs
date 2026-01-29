import '../models/song.dart';

class ApiService {
  final String _baseUrl =
      'https://scripturesongs.ethnos.dev/audio/philippians/';

  // Centralized data source to ensure we can look up songs by ID
  List<Song> _getAllSongsInternal() {
    return [
      // Philippians
      Song(
        id: '1',
        title: 'Grace and peace to you',
        reference: 'Philippians 1:1-2',
        url: '${_baseUrl}01-Grace-and-peace-to-you.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '2',
        title: 'In every prayer',
        reference: 'Philippians 1:3-11',
        url: '${_baseUrl}02-In-every-prayer.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '3',
        title: 'By my chains',
        reference: 'Philippians 1:12-20',
        url: '${_baseUrl}03-By-my-chains.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '4',
        title: 'For to me to live is Christ',
        reference: 'Philippians 1:20-26',
        url: '${_baseUrl}04-For-to-me-to-live-is-Christ.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '5',
        title: 'Side by side',
        reference: 'Philippians 1:27-30',
        url: '${_baseUrl}05-Side-by-side.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '6',
        title: 'In humility',
        reference: 'Philippians 2:1-4',
        url: '${_baseUrl}06-In-humility.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '7',
        title: 'Let this mind be in you',
        reference: 'Philippians 2:5-11',
        url: '${_baseUrl}07-Let-this-mind-be-in-you.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '8',
        title: 'For it is God who works in you',
        reference: 'Philippians 2:12-13',
        url: '${_baseUrl}08-For-it-is-God-who-works-in-you.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '9',
        title: 'Blameless and pure',
        reference: 'Philippians 2:14-18',
        url: '${_baseUrl}09-Blameless-and-pure.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '10',
        title: 'Proven worth',
        reference: 'Philippians 2:19-24',
        url: '${_baseUrl}10-Proven-worth.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '11',
        title: 'Fellow soldier',
        reference: 'Philippians 2:25-30',
        url: '${_baseUrl}11-Fellow-soldier.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '12',
        title: 'I want to know Christ',
        reference: 'Philippians 3:1-11',
        url: '${_baseUrl}12-I-want-to-know-Christ.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '13',
        title: 'I press on',
        reference: 'Philippians 3:10-16',
        url: '${_baseUrl}13-I-press-on.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '14',
        title: 'Our citizenship is in heaven',
        reference: 'Philippians 3:17-21',
        url: '${_baseUrl}14-Our-citizenship-is-in-heaven.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '15',
        title: 'My joy and crown',
        reference: 'Philippians 4:1-3',
        url: '${_baseUrl}15-My-joy-and-crown.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '16',
        title: 'The peace of God',
        reference: 'Philippians 4:4-7',
        url: '${_baseUrl}16-The-peace-of-God.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '17',
        title: 'Think on these things',
        reference: 'Philippians 4:8-9',
        url: '${_baseUrl}17-Think-on-these-things.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '18',
        title: 'Content',
        reference: 'Philippians 4:10-13',
        url: '${_baseUrl}18-Content.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '19',
        title: 'My God will supply all your needs',
        reference: 'Philippians 4:14-20',
        url: '${_baseUrl}19-My-God-will-supply-all-your-needs.mp3',
        collection: 'philippians',
      ),
      Song(
        id: '20',
        title: 'Greet all the saints in Christ Jesus',
        reference: 'Philippians 4:21-23',
        url: '${_baseUrl}20-Greet-all-the-saints-in-Christ-Jesus.mp3',
        collection: 'philippians',
      ),

      // Jude (Placeholders)
      Song(
        id: '21',
        title: 'Jude 1-2',
        reference: 'Jude 1-2',
        url: '${_baseUrl}01-Grace-and-peace-to-you.mp3',
        collection: 'jude',
      ),
      Song(
        id: '22',
        title: 'Jude 3-4',
        reference: 'Jude 3-4',
        url: '${_baseUrl}02-In-every-prayer.mp3',
        collection: 'jude',
      ),
    ];
  }

  Future<List<Song>> fetchSongsForCollection(String collection) async {
    // Filter the master list based on the collection string
    return _getAllSongsInternal()
        .where((s) => s.collection == collection)
        .toList();
  }

  // Helper to reconstruct favorites from saved IDs
  Future<List<Song>> getSongsByIds(List<String> ids) async {
    final allSongs = _getAllSongsInternal();
    return allSongs.where((song) => ids.contains(song.id)).toList();
  }
}
