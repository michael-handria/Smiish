//
//  ChatViewController.swift
//  Smiish
//
//  Created by Michael Handria on 3/26/18.
//  Copyright © 2018 Michael Handria. All rights reserved.
//

import UIKit
import UserNotifications
import Toaster
//import SocketIO

//struct to hold the message data coming in
struct Messages{
    var name: String
    var message: String
    var systemTime: String

    init(name: String, message: String, systemTime: String){
        self.name = name
        self.message = message
        self.systemTime = systemTime
    }
}

class ChatViewController: UIViewController{

    //holds the app user's data of roomname that
    //he/she is in and the username he/she selected
    var userName: String = ""
    var roomName: String = ""
    open static var messageBadge: Int = 0

    let center = UNUserNotificationCenter.current()
    let notification = UNMutableNotificationContent()

    var messages = [Messages]()
    
    var clientList = [String]()


    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var msgContent: ChatField!

    //Bottom portion of View that includes MsgContent and SendButton
    let messageInputView: UIView = {
        let view = UIView()
        return view
    }()
    
    //Adding Custom NavigationBar
    let customNavigationBar: UIView = {
        let view = UIView()
        return view
    }()
    
    let roomNameNaviBar: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let leaveRoom: UIButton = {
        let button = UIButton()
        return button
    }()
    


    /* CONSTRUCTOR
     summary:
        custom custroctor for this specific controller
        (empty for now can be overloaded for later implementation if necessary)
    */
    init(){
        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /*  ViewDidAppear

     Notifies the view controller that its view was added to a view hierarchy.
    */
    override func viewDidAppear(_ animated: Bool) {
        //Show Navigation Controller in Chat VC
        self.navigationController?.isNavigationBarHidden = true
        ChatViewController.messageBadge = 0
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Socket.default.socket.emit("clients in room")

        //reset badge for notifications
        ChatViewController.messageBadge = 0
        
        leaveRoom.addTarget(self, action: #selector(leaveRoomButton), for: .touchUpInside)

        //Gesture for swiping back
        let rightSwipeBack = UISwipeGestureRecognizer(target: self, action: #selector(self.goBack))
        rightSwipeBack.direction = .right

        tableView.addGestureRecognizer(rightSwipeBack)

        //Notify when keyboard appears
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        //Add Subviews within chatVC
        addView()

        //Call standardLayout Func
        standardLayout()
        
        //Call StyleView Func
        styleViews()


        //give table delegate.
        //basically allows the tableView utilize the
        //extension code written below
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))

        tableView.addGestureRecognizer(tap)
        
        msgContent.autocorrectionType = .no
        
        
        //Call clients in room to api
        //Socket.default.socket.emit("clients in room")

        //socket event
        Socket.default.socket.on("chat message") { (data, ack) in
          if let dict = data[0] as? Dictionary<String, String>{
              if let name = dict["username"], let time = dict["systemTime"], let msg = dict["message"]{
                   self.insertMsgArray(name: name, time: time, msg: msg)
              }
          }
        }
        
        //TODO: add Socket.on "get clients"
        Socket.default.socket.on("get clients"){ (data, ack) in

//            let name = data["username"]
            let dict = data[0] as? NSMutableDictionary
                // IT IS NOT REACHING THIS POINT!!!!!!!!!
            let name = dict?["username"]
            let room = dict?["roomName"]
            let id  =  dict?["id"]
            let valid = dict?["userValidation"] as? Int
            print(self.clientList)
            print("Validate3")
            let res = ["username":name, "roomName": room, "id":id,"clientList":self.clientList]
//            if let validate = dict?["userValidation"] {
            if(valid == 1){
                print("Validate5")
                //New User Joined Perform validation on user name with client list
                Socket.default.socket.emit("client list", res)
            }else{
                //Use this to make client list
                print("Test client list clear")
                print(self.clientList)
                self.clientList.removeAll()
                print("Clear")
                print(self.userName)
                Socket.default.socket.emit("present", ["username": self.userName])
                print("False")
            }
//            }
        }
        
        //Chat Room Exists and user has an unique name
        Socket.default.socket.on("add new user"){ (data, ack) in
            let args = ["username": self.userName, "roomName": self.roomName]
            //TODO: Socket.Emit "Add to room"
            Socket.default.socket.emit("add to room",args)
        }
        
        //Show new user has joined
        Socket.default.socket.on("new user"){ (data, ack) in
            if let dict = data[0] as? NSMutableDictionary{
                if let name = dict["username"], let numUser = dict["numUsers"]{
                    Toast(text: "\(name ) has joined the room with: \(numUser) users").show()
                    ToastView.appearance().backgroundColor = .white
                    ToastView.appearance().textColor = #colorLiteral(red: 0.7007569624, green: 0.008493066671, blue: 0.0166539277, alpha: 1)
                    ToastView.appearance().font = UIFont(name: "Pacifico-Regular", size: 13)
                }
            }
        }
        //TODO: user Join
        Socket.default.socket.on("user join"){ (data,ack) in
            print("USER JOINED")
            print(self.clientList)
            if let dict = data[0] as? Dictionary<String, String>{
                if let name = dict["username"], let room = dict["roomName"]{
                    Toast(text: "\(name) has joined the room with: \(room) users").show()
                    ToastView.appearance().backgroundColor = .white
                    ToastView.appearance().textColor = #colorLiteral(red: 0.7007569624, green: 0.008493066671, blue: 0.0166539277, alpha: 1)
                    ToastView.appearance().font = UIFont(name: "Pacifico-Regular", size: 13)
                
                }
            }
            Socket.default.socket.emit("clients in room")
        }
        //TODO: clientList
        
        //TODO: client response - adds the username into the clientList and add Toast for who joined
        Socket.default.socket.on("client response"){(data,ack) in
            print("1")
            print(data)
            if let dict = data[0] as? NSMutableDictionary{
                print(dict)
                print("2")
                if let name = dict["username"]{
                    //append to the clientList
                    print("client response")
                    self.clientList.append(name as! String)
                    print(self.clientList)
                }
            }

        }
        
        Socket.default.socket.emit("clients in room")

        
        // Do any additional setup after loading the view.
    }

    @objc func keyboardWillShow(notification: NSNotification){
        let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        if bottomConstraint?.constant == 0{
            //Check if Iphone X
            if #available(iOS 11.0, *) {
                 bottomConstraint?.constant = -keyboardSize!.height  - 25
            }else{
                 bottomConstraint?.constant = -keyboardSize!.height
            }
        }else{
            bottomConstraint?.constant = 0
        }
    }
    
    @IBAction func leaveRoom(sender: UIButton ){
        Socket.default.closeConnection()
        self.navigationController?.popViewController(animated: true)
    }


    /*
     @summary:
        this function will be used to dismiss the keyboard from the view
    */
    @objc override func dismissKeyboard() {
        view.endEditing(true)
        tableView.reloadData()
    }

    /*
     @summary:
        function is called as a swipe left gesture
        this will pop the current view and bring user to
        the last view before going to this view
        -> basically a go back button
     params:
        sender - swipe left gesture.
    */
    @objc func goBack(sender: UISwipeGestureRecognizer){
        Socket.default.closeConnection()
        self.navigationController?.popViewController(animated: true)

    }

    override func viewDidDisappear(_ animated: Bool) {
        Socket.default.socket.emit("disconnect")
        Socket.default.socket.off("chat message")
        Socket.default.socket.off("new user")
        Socket.default.socket.off("get clients")
    }

    /*
     @summary:
        function will insert new message to the array and
        send reload table view as well as scroll to the last, newly added, cell
        of the table view
     params:
        name - username that sent the msg
        msg - content to be displayed "user message"
    */
    func insertMsgArray(name: String, time: String, msg: String){

        //append on the message array when the user sends a message
        messages.append(Messages(name: name, message: msg, systemTime: time))

        //table must be reloaded in order to show the incomming data.
        tableView.reloadData()

        //function to notify users
        notifyUsers(name: (name+" "+time), msg: msg)

        //perform this ASYNCRONOUSLY to scroll to the last cell that has just been added in.
        DispatchQueue.main.async {
            //get an index path (last row) then scroll to bottom of added msg.
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    /*
     @summary:
        function will notify users, if users enters app in background mode, that a notification
        is comming in
     params:
        name - username
        msg - text content to notify the user with.
     */
    func notifyUsers(name: String, msg: String){
        let status = UIApplication.shared.applicationState
        if status.rawValue == 2{
            ChatViewController.messageBadge = ChatViewController.messageBadge + 1
            notification.title = name
            notification.body = msg
            notification.badge = NSNumber(value: ChatViewController.messageBadge)
            notification.sound = UNNotificationSound.default()
            let request = UNNotificationRequest(identifier: "user notify", content: notification, trigger: nil)
            center.add(request)
        }
    }

    /*
     Generated by Xcode
    */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     @summary:
        function called when app user press the send button to "emit" the message.
     params:
        sender - UIButtonView that calls this function
    */
    @IBAction func sendMsg(_ sender: UIButton) {
        if(msgContent.text.isEmpty){
            //Add Here when you want to send SMIISH Image to other people
            //Socket.default.socket.emit("chat message", "SMIIS" )
        }else{
            Socket.default.socket.emit("chat message", msgContent.text)
            msgContent.text = ""
        }
        //view.endEditing(true)
    }
    
    @objc func leaveRoomButton(_sender: UIButton){
        Socket.default.closeConnection()
        self.navigationController?.popViewController(animated: true)
    }

    /*
     @summary:
        This func will add all the subviews used in chatVC
    */
    func addView(){
        //Portion of view in the bottom of the screen
        view.addSubview(customNavigationBar)
        customNavigationBar.addSubview(leaveRoom)
        customNavigationBar.addSubview(roomNameNaviBar)
        view.addSubview(messageInputView)
        messageInputView.addSubview(msgContent)
        messageInputView.addSubview(sendButton)
    }

    /* StyleViews

        Add Style to VC

    */
    private func styleViews(){
        
        
        
        customNavigationBar.backgroundColor = .white
        
    
        leaveRoom.setTitle("Leave", for: .normal)
        leaveRoom.titleLabel?.font = UIFont(name: "Pacifico-Regular", size: 20)
        leaveRoom.setTitleColor(#colorLiteral(red: 0.7007569624, green: 0.008493066671, blue: 0.0166539277, alpha: 1), for: .normal)
        
        roomNameNaviBar.text = roomName
        roomNameNaviBar.textColor = #colorLiteral(red: 0.7007569624, green: 0.008493066671, blue: 0.0166539277, alpha: 1)
        //roomNameNaviBar.backgroundColor = .gray
        roomNameNaviBar.textAlignment = .center
        roomNameNaviBar.font = UIFont(name:"Pacifico-Regular", size: 20)
        
        sendButton.layer.cornerRadius = 12
        sendButton.titleLabel?.font = UIFont(name: "Pacifico-Regular", size: 15)
        
        //msgContent.textContainerInset = UIEdgeInsetsMake(<#T##top: CGFloat##CGFloat#>, <#T##left: CGFloat##CGFloat#>, <#T##bottom: CGFloat##CGFloat#>, <#T##right: CGFloat##CGFloat#>)
    }

    /* standardLayout func

        Func called to add constraints within the VC

    */

    //Bottom Constraint used for Keyboard will show
    var bottomConstraint: NSLayoutConstraint?

    private func standardLayout(){

        customNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        customNavigationBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        customNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        customNavigationBar.bottomAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        
        leaveRoom.translatesAutoresizingMaskIntoConstraints = false
        leaveRoom.leadingAnchor.constraint(equalTo: customNavigationBar.leadingAnchor).isActive = true
        leaveRoom.topAnchor.constraint(equalTo: customNavigationBar.topAnchor).isActive = true
        leaveRoom.bottomAnchor.constraint(equalTo: customNavigationBar.bottomAnchor).isActive = true
        
        roomNameNaviBar.translatesAutoresizingMaskIntoConstraints = false
        roomNameNaviBar.centerXAnchor.constraint(equalTo: customNavigationBar.centerXAnchor).isActive = true
        roomNameNaviBar.topAnchor.constraint(equalTo: customNavigationBar.topAnchor).isActive = true
        roomNameNaviBar.bottomAnchor.constraint(equalTo: customNavigationBar.bottomAnchor).isActive = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: customNavigationBar.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor).isActive = true

        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        messageInputView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        messageInputView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        bottomConstraint = NSLayoutConstraint(item: messageInputView, attribute: .bottom, relatedBy: .equal , toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)

        //messageInputView.backgroundColor = .blue


        //Msg Content Constraints
        msgContent.translatesAutoresizingMaskIntoConstraints = false
        msgContent.heightAnchor.constraint(equalToConstant: 30).isActive = true
        msgContent.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 10).isActive = true
        msgContent.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10).isActive = true
        msgContent.topAnchor.constraint(equalTo: messageInputView.topAnchor, constant: 10).isActive = true
        msgContent.bottomAnchor.constraint(equalTo: messageInputView.bottomAnchor, constant: -10).isActive = true

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: msgContent.trailingAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -10).isActive = true
        sendButton.topAnchor.constraint(equalTo: messageInputView.topAnchor, constant: 10).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: messageInputView.bottomAnchor, constant: -10).isActive = true

    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource{

    //number of sections that the table will have.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //get the count of the cells into the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //get current message data to be displayed on the table
        let messageNew = self.messages[indexPath.row]
        //a boolean that can determine whether or not the
        //last message added to the table is sent by the current message
        //to be displayed
        var displayName = (indexPath.row == 0)
        if(indexPath.row > 0){
            displayName = (self.messages[indexPath.row-1].name != messageNew.name)
            //displayName = displayName; +" @ " + messageNew.systemTime
        }

        //messageNew.systemTime + "\n" +  this is for adding systemtime
        let content =  messageNew.message


        //determine what type of cell will go into the table view
        if(displayName){
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellView", for: indexPath) as! MessageCellWithName
            cell.setCell(name: messageNew.name+" @ " + messageNew.systemTime, msg: content, senderName: self.userName + " @ " + messageNew.systemTime)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellViewNoName", for: indexPath) as! MessageCellNoName
            cell.setCell(name: messageNew.name, msg: content, senderName: self.userName)
            return cell
        }
    }
}
