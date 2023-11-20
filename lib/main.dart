import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share and Save Image',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MyHome(),
    );
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final imageController = WidgetsToImageController();
  String urlImage = "https://cdn-images-1.medium.com/v2/resize:fit:716/1*4SAfN6XnN3qfj5CFyCnNlA.jpeg";
  String assetImage = "assets/flutter_file.jpg";
  Uint8List? widgetImage;
  Uint8List? imageResponse;
  Uint8List? imageAssets;
  PickedFile? pickedFileCamera;
  PickedFile? pickedFileGallery;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<File> getFileTemp(Uint8List uint8list) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/temp_image_${Random().nextInt(1000)}.png').create();
    await file.writeAsBytes(uint8list);
    print("getFileTemp:$file");
    return file;
  }

  Future<void> sharedImage({required File file, required String text}) async {
    await Share.shareFiles([file.path], text: text);
  }

  Future<void> saveImage({required File file}) async {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Guardar imagen"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () async {
                await GallerySaver.saveImage(file.path);
                myShowSnackBar(message: "Se guardo correctamente");
                Navigator.pop(context);
              },
              child: const Text("Guardar")),
        ],
      ),
    );
  }

  myShowSnackBar({required String message}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), action: SnackBarAction(label: 'Aceptar', onPressed: () {})));
  }

  @override
  Widget build(BuildContext context) {
    double sizeWidth = MediaQuery.sizeOf(context).width;
    double sizeHeight = MediaQuery.sizeOf(context).height;
    return DefaultTabController(
      initialIndex: 0,
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Imagen"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.screenshot), text: "Widget to Image"),
              Tab(icon: Icon(Icons.image), text: "Galeria"),
              Tab(icon: Icon(Icons.camera), text: "Camara"),
              Tab(icon: Icon(Icons.download), text: "Internet"),
              Tab(icon: Icon(Icons.file_open), text: "Archivos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WidgetsToImage(controller: imageController, child: ticket(sizeWidth)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          onPressed: () async {
                            myShowSnackBar(message: "Capturando...");
                            widgetImage = await imageController.capture();
                            setState(() {});
                            if (widgetImage != null) {
                              final _file = await getFileTemp(widgetImage!);
                              saveImage(file: _file);
                            }
                          },
                          icon: const Icon(Icons.save)),
                      IconButton(
                          onPressed: () async {
                            widgetImage = await imageController.capture();
                            myShowSnackBar(message: "Capturando...");
                            setState(() {});
                            if (widgetImage != null) {
                              final file = await getFileTemp(widgetImage!);
                              sharedImage(file: file, text: 'Image Flutter Share');
                            }
                          },
                          icon: const Icon(Icons.share)),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              widgetImage = null;
                            });
                          },
                          icon: const Icon(Icons.delete)),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    width: sizeWidth * 0.6,
                    height: sizeHeight * 0.4,
                    child: (widgetImage != null) ? Image.memory(widgetImage!, fit: BoxFit.fill) : const Placeholder(),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: sizeWidth * 0.6,
                  height: sizeWidth * 0.6,
                  child: (pickedFileGallery != null) ? Image.file(File(pickedFileGallery!.path)) : const Placeholder(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    pickedFileGallery = await ImagePicker.platform.pickImage(source: ImageSource.gallery);
                    setState(() {});

                    if (pickedFileGallery != null) {
                      myShowSnackBar(message: "Imagen seleciona...");
                    } else {
                      myShowSnackBar(message: "No seleccionio Imagen...");
                    }
                  },
                  child: const Text("Selecionar imagen"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () async {
                          if (pickedFileGallery != null) {
                            saveImage(file: File(pickedFileGallery!.path));
                          }
                        },
                        icon: const Icon(Icons.save)),
                    IconButton(
                        onPressed: () async {
                          setState(() {});
                          if (pickedFileGallery != null) {
                            sharedImage(file: File(pickedFileGallery!.path), text: 'Image Flutter Share');
                          }
                        },
                        icon: const Icon(Icons.share)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            pickedFileGallery = null;
                          });
                        },
                        icon: const Icon(Icons.delete)),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: sizeWidth * 0.6,
                  height: sizeWidth * 0.6,
                  child: (pickedFileCamera != null) ? Image.file(File(pickedFileCamera!.path)) : const Placeholder(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    pickedFileCamera = await ImagePicker.platform.pickImage(source: ImageSource.camera);
                    setState(() {});
                    if (pickedFileCamera != null) {
                      myShowSnackBar(message: "Foto capturada...");
                    } else {
                      myShowSnackBar(message: "Foto no capturada...");
                    }
                  },
                  child: const Text("Captura una foto"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () async {
                          if (pickedFileCamera != null) {
                            saveImage(file: File(pickedFileCamera!.path));
                          }
                        },
                        icon: const Icon(Icons.save)),
                    IconButton(
                        onPressed: () async {
                          setState(() {});
                          if (pickedFileCamera != null) {
                            sharedImage(file: File(pickedFileCamera!.path), text: 'Image Flutter Share');
                          }
                        },
                        icon: const Icon(Icons.share)),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            pickedFileCamera = null;
                          });
                        },
                        icon: const Icon(Icons.delete)),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(urlImage, width: sizeHeight * 0.4, height: sizeHeight * 0.4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () async {
                          Response response = await get(Uri.parse(urlImage));
                          if (response.statusCode == 200) {
                            imageResponse = response.bodyBytes;
                            final file = await getFileTemp(response.bodyBytes);
                            saveImage(file: file);
                          }
                        },
                        icon: const Icon(Icons.save)),
                    IconButton(
                        onPressed: () async {
                          Response response = await get(Uri.parse(urlImage));
                          if (response.statusCode == 200) {
                            imageResponse = response.bodyBytes;
                            setState(() {});
                            final file = await getFileTemp(response.bodyBytes);
                            sharedImage(file: file, text: 'Image Flutter Share');
                          }
                        },
                        icon: const Icon(Icons.share)),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(assetImage, width: sizeHeight * 0.4, height: sizeHeight * 0.4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () async {
                          final ByteData bytes = await rootBundle.load(assetImage);
                          imageAssets = bytes.buffer.asUint8List();
                          if (imageAssets != null) {
                            final file = await getFileTemp(imageAssets!);
                            saveImage(file: file);
                          }
                        },
                        icon: const Icon(Icons.save)),
                    IconButton(
                        onPressed: () async {
                          final ByteData bytes = await rootBundle.load(assetImage);
                          imageAssets = bytes.buffer.asUint8List();
                          if (imageAssets != null) {
                            final file = await getFileTemp(imageAssets!);
                            sharedImage(file: file, text: "Image Flutter Share");
                          }
                        },
                        icon: const Icon(Icons.share)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Container ticket(double sizeWidth) {
    return Container(
      width: sizeWidth * 0.8,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.black), color: Colors.white),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fecha:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("19/11/2013", style: TextStyle(fontSize: 16)),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hora:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("12:30PM", style: TextStyle(fontSize: 16)),
            ],
          ),
          const Text('Tienda de la esquina', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ListView.builder(
            itemCount: 7,
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            itemBuilder: (context, index) => ListTile(
              title: Text("Nombre Item:$index"),
              subtitle: Text("Descripcion Item:$index"),
              trailing: Text("\$ ${Random().nextInt(1000)}"),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$ 200', style: TextStyle(fontSize: 16)),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Iva:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('16 %', style: TextStyle(fontSize: 16)),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$ 216.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
