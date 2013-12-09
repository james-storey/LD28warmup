import 'dart:html';
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math';
import 'dart:web_audio';

Scene scene;
WebGLRenderer renderer;
PerspectiveCamera camera;
Cubee cube;
SoundEffect sfx;
num mouseX;
num bounds = 300.0;


class Cubee
{
  Mesh mesh;
  Vector3 v;
  num speed;
  num size;
  Vector3 lightPos;
  Cubee(){
    size = 100.0;
    lightPos = new Vector3(bounds, bounds, bounds);
    Map un = { "lightPos": new Uniform.vector3(lightPos.x, lightPos.y, lightPos.z) };
    mesh = new Mesh(new CubeGeometry(size, size, size), 
                    new ShaderMaterial(fragmentShader: fragShader(), vertexShader: vertShader(), uniforms: un ));
    scene.add(mesh);
    
    v = new Vector3(randFloat(0.0, 1.0), randFloat(0.0, 1.0), randFloat(0.0, 1.0));
    v.normalize();
    speed = 10.0;
  }
  
  String vertShader() {
    String vert = "";
    vert += """
      uniform vec3 lightPos;

      varying vec3 vlightDir;
      varying vec3 vNormal;
      void main() {
        vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
        vNormal = normal;
        vec4 viewLight = modelViewMatrix * vec4(lightPos, 1.0);
        vlightDir = viewLight.xyz - mvPosition.xyz;
        gl_Position = projectionMatrix * mvPosition;
      }""";
    return vert;
  }
  
  String fragShader(){
    String frag = "";
    frag += """
      varying vec3 vlightDir;
      varying vec3 vNormal;
      void main() {
        float diffuse = 0.002 * max(dot(vNormal, vlightDir), 0.1);
        gl_FragColor = vec4(diffuse, diffuse, diffuse, 1.0); 
      }""";
    return frag;
  }
  
  update()
  {
    bool edge = true;
    if(mesh.position.x > bounds)
    {
      mesh.position.x = bounds;
      reflectV(new Vector3(-1.0, 0.0, 0.0));
    }
    else if (mesh.position.x < -bounds)
    {
      mesh.position.x = -bounds;
      reflectV(new Vector3(1.0, 0.0, 0.0));
    }
    else if(mesh.position.y > bounds)
    {
      mesh.position.y = bounds;
      reflectV(new Vector3(0.0, -1.0, 0.0));
    }
    else if (mesh.position.y < -bounds)
    {
      mesh.position.y = -bounds;
      reflectV(new Vector3(0.0, 1.0, 0.0));
    }
    else if(mesh.position.z > bounds)
    {
      mesh.position.z = bounds;
      reflectV(new Vector3(0.0, 0.0, -1.0));
    }
    else if (mesh.position.z < -bounds)
    {
      mesh.position.z = -bounds;
      reflectV(new Vector3(0.0, 0.0, 1.0));
    }
    else
    {
      edge = false;
    }
    
    if(edge == true) {
      sfx.play();
    }

    mesh.position += v*speed;
    mesh.rotation.y += 0.01;
    mesh.rotation.z += 0.008;
    
  }
  
  Vector3 reflectV(Vector3 n)
  { 
    Vector3 vc = v.clone();
    v = vc - ((v.multiply(n)).multiply(n) * 2.0);
    
    return v;
  }
}

class SoundEffect {
  String soundPath = "assets/hit.wav";
  AudioBuffer aBuff;
  AudioContext aCtx;
  AudioBufferSourceNode source;
  GainNode gNode;
  SoundEffect(){
    aCtx = new AudioContext();
    gNode = aCtx.createGainNode();
    var request = new HttpRequest();
    request.open("GET", soundPath, async:true);
    request.responseType = "arraybuffer";
    request.onLoad.listen((e) => this._onLoad(request));
    
    gNode.gain.value = 1.0;
    
    request.send();
  }
  void play ()
  {
     source = aCtx.createBufferSource();
     source.buffer = aBuff;
     source.connectNode(gNode);
     gNode.connectNode(aCtx.destination);
     source.start(0);
     source.loop = false;
  }
  
  _onLoad(HttpRequest request)
  {
    aCtx.decodeAudioData(request.response).then((AudioBuffer audio) {
      if(audio == null) {
        window.alert(" error: no data decoded");
        return;
      }
      aBuff = audio;
    }).catchError((error) => print("failed to read audio file"));
  }
}

void main() {
  init();
  animate(0);
}

void init() {
  Element container = document.querySelector('#container');
  
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 8000.0)
  ..position.z = 4 * bounds;
  
  scene = new Scene();
  
  camera.lookAt(scene.position);
  
  renderer = new WebGLRenderer(antialias:false, clearColorHex: 0x050505, clearAlpha: 1, alpha: false)
  ..setSize(window.innerWidth, window.innerHeight);
  
  container.children.add(renderer.domElement);
  
  window.onResize.listen(onWindowResize);
  
  cube = new Cubee();
  scene.add(cube.mesh);
  
  Mesh boundingCube = new Mesh(new CubeGeometry(2*bounds, 2*bounds, 2*bounds), new MeshBasicMaterial(wireframe:true));
  scene.add(boundingCube);
  container.onMouseMove.listen(mouseListener);
  mouseX = 0.0;
  sfx = new SoundEffect();
}

void mouseListener(MouseEvent event)
{
  mouseX = event.client.x;
}

onWindowResize(event) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  
  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num n) {
  window.requestAnimationFrame( animate );
  cube.update();
  camera.position.x = sin(mouseX * 0.01) * 4 * bounds;
  camera.position.z = cos(mouseX * 0.01) * 4 * bounds;
  camera.lookAt(new Vector3.zero());
  render();
}

render() {
  renderer.render(scene, camera);
}
