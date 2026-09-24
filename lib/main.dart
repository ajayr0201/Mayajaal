import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

void main() {
  runApp(const MayajaalApp());
}

class MayajaalApp extends StatelessWidget {
  const MayajaalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mayajaal Streamer',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppLinks _appLinks;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  bool _isLoading = false;
  String _statusMessage = "Website se link open karne ka intazar hai...";
  String? _downloadUrl;
  String _fileName = "";

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'teracloud' && uri.host == 'f') {
        String shortCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (shortCode.isNotEmpty) {
          _fetchAndPlayFile(shortCode);
        }
      }
    });
  }

  Future<void> _fetchAndPlayFile(String shortCode) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "File fetch ho rahi hai...";
    });

    try {
      final response = await http.get(
        Uri.parse('https://1-9102.vercel.app/api/file-info?code=$shortCode')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String videoUrl = data['fileUrl'];
        _fileName = data['fileName'];
        _downloadUrl = videoUrl;

        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          allowFullScreen: true,
          showControls: true,
        );

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = "File nahi mili ya error aaya.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mayajaal Player'),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _fileName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          if (_downloadUrl != null) {
                            FileDownloader.downloadFile(
                              url: _downloadUrl!,
                              name: _fileName,
                            );
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text("High Speed Download"),
                      )
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
      ),
    );
  }
}
