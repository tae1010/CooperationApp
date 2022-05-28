//
//  ProjectViewController.swift
//  CooperationApp
//
//  Created by 김정태 on 2022/05/11.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProjectViewController: UIViewController {
    
    //ProjectContent(id: String, countIndex: Int, content: Dictionary<String, [String]>)
    var projectContent = [ProjectContent]() // project model 배열
    
    var content = [String]() //projectcontent model의 content.value값을 저장 [String] // currentCount값에 따라 바뀜
    
    var ref: DatabaseReference! = Database.database().reference()
    var id: String = "" // 프로젝트의 uuid값을 받을 변수
    var currentCount: Int = 0 //현재 페이지
    var currentTitle: String = "이름없음"
    
    @IBOutlet weak var contentTitleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let tableViewNib = UINib(nibName: "ProjectContentCell", bundle: nil)
        self.tableView.register(tableViewNib, forCellReuseIdentifier: "ProjectContentCell")
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.readDB()
        self.readContents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.projectContent.removeAll()
        self.content.removeAll()
    }
    
    //뒤로가기 버튼(Maintabbarview로 돌아감)
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: false)
    }
    
    @IBAction func cardEditButton(_ sender: UIButton) {
        self.tableView.setEditing(true, animated: true) //편집모드 실행
    }
    
    @IBAction func addCardView(_ sender: UIButton) {
        let email = self.emailToString(Auth.auth().currentUser?.email ?? "고객")
        let alert = UIAlertController(title: "카드 추가", message: nil, preferredStyle: .alert)
        //alert 등록버튼
        let registerButton = UIAlertAction(title: "추가", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            guard let content = alert.textFields?[0].text else { return }
            
            // 경로중 self.content.count라고 안하고 "\(self.content.count)" 라고 작성한 이유는 경로를 찾을때는 string값만 허용
            // content 값 작성
            self.ref.child("\(email)/\(self.id)/content/\(self.currentCount)/\(self.currentTitle)").updateChildValues(["\(self.content.count)": content])
            
            self.content.append(content)
            self.projectContent[self.currentCount].content[self.currentTitle] = self.content
            //projectContent 배열에도 append를 해줘야함
            
            
            print(self.content)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        //alert 취소버튼
        let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(registerButton)
        alert.addAction(cancelButton)
        
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "내용을 입력해주세요."
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addListButton(_ sender: UIButton) {
        let email = self.emailToString(Auth.auth().currentUser?.email ?? "고객")
        let alert = UIAlertController(title: "리스트 추가", message: nil, preferredStyle: .alert)
        
        let registerButton = UIAlertAction(title: "추가", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            guard let content = alert.textFields?[0].text else { return }
            self.ref.child("\(email)/\(self.id)/content/\(self.projectContent.count)/\(content)").updateChildValues(["0": "카드를 추가해주세요"])
            let pc = ProjectContent(id: self.id, countIndex: self.projectContent.count, content: ["\(content)": ["카드를 추가해주세요"]])
            self.projectContent.append(pc)
        })
        
        //alert 취소버튼
        let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(registerButton)
        alert.addAction(cancelButton)
        
        alert.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "내용을 입력해주세요."
        })
        
        self.present(alert, animated: true, completion: nil)
        
    }
                                           
    @IBAction func moveLeft(_ sender: UIButton) {
        if currentCount > 0 {
            self.currentCount -= 1
            self.readContents()
            DispatchQueue.main.async {
                self.contentTitleLabel.text = self.currentTitle
                self.tableView.reloadData()
                
            }
            print(self.currentCount)
        }
    }
    
    @IBAction func moveRight(_ sender: UIButton) {
        if self.projectContent.count - 1 > currentCount {

            self.currentCount += 1
            DispatchQueue.main.async {
                self.readContents()
                self.contentTitleLabel.text = self.currentTitle
                self.tableView.reloadData()
            }
            print(currentCount)
        }
    }
    
}

// 이메일을 string값으로 변환 시켜주는 메소드
// 전체 db값을 읽어오는 메소드
// db값중 content부분을 읽어오는 메소드
extension ProjectViewController {
    
    private func emailToString(_ email: String) -> String {
        let emailToString = email.replacingOccurrences(of: ".", with: ",")
        return emailToString
    }
    
    private func readDB() {
    
        let email = self.emailToString(Auth.auth().currentUser?.email ?? "고객")
        
        ref.child(email).child(id).child("content").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [Dictionary<String, [String]>] else {return}
            
            for content in value {
                guard let count = value.firstIndex(of: content) else { return }
                let pc = ProjectContent(id: self.id, countIndex: count, content: content)
                self.projectContent.append(pc)
            }
            
            DispatchQueue.main.async {
                self.contentTitleLabel.text = self.currentTitle
                self.tableView.reloadData()
                
            }
            
            print("readDB실행",self.projectContent)
            
        }) { error in
          print(error.localizedDescription)
        }
    }
    
    //readDB에서 저장시킨 projectContent모델에서 현재 페이지의 content.value(content의 내용)값과 content.key(content의 title)를 저장시키는 함수, contentTitleLabel의 text값을 바꿔줌
    private func readContents() {
        for pc in self.projectContent{
            if pc.countIndex == currentCount {
                //2차원 배열을 1차원으로 바꿔줌
                self.currentTitle = pc.content.keys.joined(separator: "")
                self.content = Array(pc.content.values.joined())
            }
        }
        print("readContents실행",self.content)
        
    }
    
}

extension ProjectViewController: UITableViewDelegate {
    
}

extension ProjectViewController: UITableViewDataSource {
    //content의 배열 인덱스 갯수 만큼 return
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectContentCell", for: indexPath) as! ProjectContentTableViewCell
        cell.content.text = self.content[indexPath.row]
        cell.layer.cornerRadius = 10
        return cell
    }
    
    //편집모드에서 할일의 순서를 변경하는 메소드(canmoverowat, moverowat)
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

    }
    
    //편집모드에서 삭제버튼을 누를떄 어떤셀인지 알려주는 메서드
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //편집모드에서 삭제할수 있고 편집모드를 들어가지 않아도 스와이프로 삭제가능
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        }

    }
    
}
