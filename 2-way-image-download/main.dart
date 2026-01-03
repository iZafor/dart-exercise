import 'worker.dart';

// URLs to process:
const urls = [
  'https://picsum.photos/200/300',
  'https://picsum.photos/400/400',
  'https://example.com/bad-image.jpg',
  'https://picsum.photos/800/600',
  'https://picsum.photos/1024/768',
  'https://images.pexels.com/photos/267961/pexels-photo-267961.jpeg',
  'https://images.pexels.com/photos/746386/pexels-photo-746386.jpeg',
];

// Allowed domains for validation:
const allowedDomains = [
  'picsum.photos',
  'images.unsplash.com',
  'images.pexels.com',
];

void main(List<String> args) async {
  final worker = await Worker.spawn(allowedDomains);
  await worker.processUrls(urls);
  worker.close();
}
