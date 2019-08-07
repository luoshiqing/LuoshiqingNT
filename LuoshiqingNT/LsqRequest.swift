//
//  LsqRequest.swift
//  YYTimeBus
//
//  Created by DayHR on 2019/5/10.
//  Copyright © 2019 zhcx. All rights reserved.
//

import UIKit
import Alamofire

struct ImgData {
    var name: String
    var data: Data
}

typealias Success = ((JSON)->Swift.Void)?
typealias Failue = ((String)->Swift.Void)?

struct LsqRequest {

    static let sharedManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    //TODO:Alamofire
    //因为有些接口Alamofire掉不通，常见的 post、put调不通。如遇到Alamofire调不通，请使用doSystemRequest方法
    static func doRequest(url: String, method: HTTPMethod, params: Parameters?, isShowHUD: Bool, success: Success, failue: Failue){
        DispatchQueue.main.async {
            if isShowHUD{
                MBProgressHUD.showState("加载中", to: UIApplication.shared.keyWindow)
            }else{
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        let token_type = AuthLogin.shared.token_type ?? ""
        let access_token = AuthLogin.shared.access_token ?? ""
        let value = token_type + " " + access_token
        let headers: HTTPHeaders = ["Authorization": value]
        
        sharedManager.request(url, method: method, parameters: params ?? [:], headers:headers).responseData { (response) in
            DispatchQueue.main.async {
                if isShowHUD{
                    MBProgressHUD.hidden(to: UIApplication.shared.keyWindow)
                }else{
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if let error = response.error{
                    failue?(error.localizedDescription)
                }else if let data = response.value{
                    let json = JSON(data: data , options: JSONSerialization.ReadingOptions(), error: nil)
                    let statusCode = json["statusCode"].stringValue
                    if statusCode == "401"{
                        self.refreshToken(success: { (isok) in
                            self.doRequest(url: url, method: method, params: params, isShowHUD: isShowHUD, success: { (json) in
                                success?(json)
                            }, failue: { (error) in
                                failue?(error)
                            })
                        })
                    }else{
                        success?(json)
                    }
                }
            }
        }
    }
    //TODO:原生请求
    //该方法是因为有些接口Alamofire掉不通，常见的 post、put调不通。如遇到Alamofire调不通，请使用该方法
    static func doSystemRequest(with url: String, method: HTTPMethod, params: Any?, isShowHUD: Bool, success: Success, failue: Failue){
        DispatchQueue.main.async {
            if isShowHUD {
                MBProgressHUD.showState("加载中", to: UIApplication.shared.keyWindow!)
            }else{
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        let mySession = URLSession.shared
        //校验url正确性
        guard let fullURL = URL(string: url) else{
            if isShowHUD{
                MBProgressHUD.hidden(to: UIApplication.shared.keyWindow!)
            }else{
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            failue?("地址非法，请检查url")
            return
        }
        //校验参数
        var data: Data?
        if let p = params{
            guard let msg = getJSONString(with: p), let tmpData = msg.data(using: .utf8) else{
                failue?("参数非法，请检查参数")//参数不正确,参数转换失败
                return
            }
            data = tmpData
        }
        
        var request = URLRequest(url: fullURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = method.rawValue
        let token_type = AuthLogin.shared.token_type ?? ""
        let access_token = AuthLogin.shared.access_token ?? ""
        let value = token_type + " " + access_token

        request.addValue(value, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = data
        
        let task = mySession.dataTask(with: request) { (data, resp, error) in
            DispatchQueue.main.async {
                if isShowHUD{
                    MBProgressHUD.hidden(to: UIApplication.shared.keyWindow!)
                }else{
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if error == nil{
                    if let d = data{
                        
                        let json = JSON(data: d , options: JSONSerialization.ReadingOptions(), error: nil)
                        let statusCode = json["statusCode"].stringValue
                        if statusCode == "401"{
                            self.refreshToken(success: { (isok) in
                                self.doSystemRequest(with: url, method: method, params: params, isShowHUD: isShowHUD, success: { (json) in
                                    success?(json)
                                }, failue: { (error) in
                                    failue?(error)
                                })
                            })
                        }else{
                            success?(json)
                        }
                    }else{
                        failue?(error!.localizedDescription)
                    }
                }else{
                    failue?(error!.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    //TODO:上传图片
    static func dataFormat(url: String, dict: [String:Any], params: [ImgData], isShowHUD: Bool, success: Success = nil, failue: Failue = nil){
        DispatchQueue.main.async {
            if isShowHUD {
                MBProgressHUD.showState("上传图片中", to: UIApplication.shared.keyWindow!)
            }else{
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        let token_type = AuthLogin.shared.token_type ?? ""
        let access_token = AuthLogin.shared.access_token ?? ""
        let value = token_type + " " + access_token
        let headers: HTTPHeaders = ["Authorization": value]
        
        sharedManager.upload(multipartFormData: { (multipartFormData: MultipartFormData) in
            for i in 0..<params.count{
                let imgData = params[i]
                let name = imgData.name
                let fileName = name + ".jpg"
                multipartFormData.append(imgData.data, withName: name, fileName: fileName, mimeType: "image/jpeg")
            }
        }, to: url, headers: headers) { (encodingResult) in
            switch encodingResult{
            case .success(let upload, _, _):
                
                upload.responseData(completionHandler: { (resp) in
                    DispatchQueue.main.async {
                        if isShowHUD{
                            MBProgressHUD.hidden(to: UIApplication.shared.keyWindow)
                        }else{
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                        if let error = resp.error{
                            failue?(error.localizedDescription)
                        }else if let data = resp.value{
                            let json = JSON(data: data , options: JSONSerialization.ReadingOptions(), error: nil)
                            success?(json)
                        }else{
                            
                        }
                    }
                })
            case .failure(let encodingError):
                DispatchQueue.main.async {
                    failue?(encodingError.localizedDescription)
                }
            }
        }
    }
    
    //TODO:刷新token
    static func refreshToken(success: ((Bool)->Swift.Void)?){
        let refresh_token = AuthLogin.shared.refresh_token ?? ""
        let url = RootAuthUrl + "/uaa/oauth/token"
        let param = ["grant_type":"refresh_token",
                     "refresh_token":refresh_token,
                     "client_id":"app",
                     "client_secret":"app"]
        LsqRequest.doRequest(url: url, method: .post, params: param, isShowHUD: false, success: { (json) in
            //print(json)
            let statusCode = json["statusCode"].stringValue
            if statusCode == "200"{//401代表token失效
                if let data = json["data"].dictionaryObject {
                    let model = AuthLogin.shared
                    model.refresh_token = data["refresh_token"] as? String
                    model.scope = data["scope"] as? String
                    model.token_type = data["token_type"] as? String
                    model.access_token = data["access_token"] as? String
                    let expires_in = data["expires_in"] as? Int
                    if let exIn = expires_in{
                        model.expires_in = "\(exIn)"
                        TokenRefresh.shared.startTimer(times: exIn)
                    }
                    print("刷新token成功")
                    model.save()
                    success?(true)
                }else{
                    self.logout()
                }
            }else{//重新登录
                let name = LsqUser.shared.accountName ?? ""
                let pwd = LsqUser.shared.accountPwd ?? ""
                LoginNetwrok.authLogin(accountName: name, accountPwd: pwd, success: { (isok) in
                    print("刷新token失效，重新登录成功!->>>>>>>>>ok")
                    success?(true)
                }, failue: { (error) in
                    print("刷新token失效，重新登录失败!->>>>>>>>>false")
                    self.logout()
                })
            }
        }) { (error) in
            self.logout()
        }
    }
    
    static func logout(){
        MBProgressHUD.showError("登录已失效，请您重新登录", to: UIApplication.shared.keyWindow, delay: 1.5)
        isLogin = false//重置为未登录状态
        if let userId = LsqUser.shared.userId {
            GeTuiSdk.unbindAlias("\(userId)", andSequenceNum: "seq-1", andIsSelf: true)
        }
        //是否需要删除用户数据
        LsqUser.removeOtherData()
        TokenRefresh.shared.removeTimer()//停止全局刷新token定时器
        //移除登录信息
        AuthLogin.remove()
        //发送退出登录的通知
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: LogoutNoticeName), object: nil, userInfo: ["key":"退出成功"])
    }
    
}
