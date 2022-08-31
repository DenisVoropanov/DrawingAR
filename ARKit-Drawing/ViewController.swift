
import ARKit

class ViewController: UIViewController {
    
    
    //    MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    //    MARK: - Properties
    
    let configuration = ARWorldTrackingConfiguration()
    
    enum ObjectPlacementMode {
        case freeform, plane, image
    }
    
    var objectMode: ObjectPlacementMode = .freeform
    
    var planeNodes: [SCNNode] = []
    var objectsPlaced: [SCNNode] = []
    
    
    var selectedNode: SCNNode?
    
    
    
    //    MARK: - Methods
    
    /// Adds an object in 20 cm in front of camera
    func addNodeInFront(_ node: SCNNode) {
        //        Get current camera frame
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        let transform = frame.camera.transform
        
        // Create translation matrix
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.2
        
        translation.columns.0.x = 0
        translation.columns.1.y = 0
        translation.columns.1.x = -1
        translation.columns.0.y = 1
        
        
        node.simdTransform = matrix_multiply(transform, translation)
        
        //        Add node to scene from func addNodeToSceneRoot
        addNodeTSceneRoot(node)
        
    }
    
    func addNodeToParentRoot(_ node: SCNNode, to parentNode: SCNNode) {
        //        Clone the node for creating copies
        let clonedNode = node.clone()
        
        objectsPlaced.append(clonedNode)
        //        Add clone node to scene
        parentNode.addChildNode(clonedNode)
    }
    
    func addNodeTSceneRoot(_ node: SCNNode) {
        addNodeToParentRoot(node, to: sceneView.scene.rootNode)
    }
    
    func reloadConfiguration() {
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first, let selectedNode = selectedNode else {
            return
        }
        
        switch objectMode {
        case .freeform:
            addNodeInFront(selectedNode)
        case .plane:
            break
        case .image:
            break
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadConfiguration()
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //    MARK: - Actions
    
    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
        default:
            break
        }
    }
    
    
}
//MARK: - OptionsViewControllerDelegate
extension ViewController: OptionsViewControllerDelegate {
    
    func objectSelected(node: SCNNode) {
        dismiss(animated: true, completion: nil)
        selectedNode = node
        
    }
    
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
    }
    
    func undoLastObject() {
        
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - ARSessionDelegate
extension ViewController: ARSCNViewDelegate {
    
    func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let extend = planeAnchor.extent
        
        let width = CGFloat(extend.x)
        let height = CGFloat(extend.z)
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x -= .pi / 2
        planeNode.opacity = 0.25
        
        
        
        return planeNode
    }
    
    
    func nodeAdded(_ node:SCNNode, for anchor: ARPlaneAnchor) {

        let planeNode = createFloor(planeAnchor: anchor)
        planeNodes.append(planeNode)
        node.addChildNode(planeNode)
    }
    
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        switch anchor {
        case let planeAnchor as ARPlaneAnchor:
            nodeAdded(node, for: planeAnchor)
            
        default:
            print(#line, #function, "Unknown anchor is found")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
                
    }
    
}
