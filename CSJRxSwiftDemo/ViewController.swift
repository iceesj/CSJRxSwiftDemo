//
//  ViewController.swift
//  CSJRxSwiftDemo
//
//  Created by tom on 16/7/7.
//  Copyright © 2016年 caoshengjie. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class ViewController: UIViewController {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //1 - 发送一个completed信号
        example("empty", action: {
            let emptySequence: Observable<Int> = Observable<Int>.empty()
            let _ = emptySequence.subscribe{event in
                print("event = \(event)")
            }
            
        })
        
        //2 - 不发送任何序列的信号
        example("never") { 
            let neverSequence: Observable<Int> = Observable<Int>.never()
            let _ = neverSequence.subscribe{ _ in
                print("This block is never called.")
            }
        }
        
        //3 - 2个信号，首先是参数value，然后Completed
        example("just") { 
            let singleElementSequence:Observable<[String]> = Observable.just(["aaa","bbb"])
            let _ = singleElementSequence.subscribe{event in
                print("event = \(event)")
            }
        }
        
        //4 - sequenceOf会把传入的几个value转化成信号 依次发出去
        example("sequenceOf") { 
            let sequenceOfElements = Observable.of(["aaa","bbb"],["ccc","ddd"])
            let _ = sequenceOfElements.subscribe{
                event in
                print("sequenceOf = \(event)")
            }
        }
        
        //5 - toObservable 可以把任意符合SequenceType的转换成Observable
        example("toObservable") { 
            let sequenceOfArray = [1,2,3,4,5].toObservable()
            let _ = sequenceOfArray.subscribe{
                event in
                print("toObservable = \(event)")
            }
        }
        
        //6 - create
        self.example("create") { 
            let myJust = { (singleElement : Int) -> Observable<Int> in
                return Observable.create({ (observer) -> Disposable in
                    let error = NSError(domain: "aaaaa", code: 10000, userInfo: nil)
                    
                    observer.on(.Next(singleElement))
                    
                    if singleElement % 2 == 0{
                        observer.onError(error)
                    }else{
                        observer.on(.Completed)
                    }
                    return NopDisposable.instance
                    
                })
            }
            
            let _ = myJust(6).subscribe{
                event in
                print("event = \(event)")
            }
        }
        
        //7 - error 发送一个标志错误的信号
        example("failWith") { 
            let error = NSError(domain: "Test", code: -1, userInfo: nil)
            let erroredSequence: Observable<Int> = Observable.error(error)
            let _ = erroredSequence.subscribe{
                event in
                print("event = \(event)")
            }
        }
        
        //8 - generate 生成一个条件环境，再把这个环境中的信号发送出去
        example("generate") { 
            let generated = Observable.generate(initialState: 0, condition: { $0 < 3 }, iterate: { $0 + 1})
            let _ = generated.subscribe{
                event in
                print("event = \(event)")
            }
        }
        
        //延期 推迟
        //9 - deferred 是只有在有订阅的时候才会创建一个Observable, 这样的好处就在于创建Observable的时候 保证了数据是最新的, 例如:
        example("deferred") { 
            var value = 1
            let normalCreate : Observable<Int> = Observable.just(value)
            let deferredSequence : Observable<Int> = Observable.deferred{
                return Observable.create{
                    observer in
                    observer.on(.Next(value))
                    observer.on(.Completed)
                    return NopDisposable.instance
                }
            }
            
            value = 10
            _ = normalCreate.subscribe{
                print("normal - \($0)")
            }
            
            _ = deferredSequence.subscribe{
                print("defer - \($0)")
            }
        }
        
        //MARK: Subject
        //PublishSubject 的订阅者只会接收到从它订阅以后发送的信号
        example("PublishSubject") { 
            let subject = PublishSubject<String>()
            self.writeSequenceToConsole("1", squence: subject)
            subject.onNext("a")
            subject.onNext("b")
            self.writeSequenceToConsole("2", squence: subject)
            subject.onNext("c")
            subject.onNext("d")
            //1a,1b,1c,2c,1d,2d
        }
        
        
        //ReplaySubject 在新的订阅出现的时候会补发前几条数据, bufferSize控制着具体补发前边几条数据 , 1就是补发一条, 2就是补发两条, 以此类推
        example("ReplaySubject") { 
            let subject = ReplaySubject<String>.create(bufferSize: 2)
            self.writeSequenceToConsole("1", squence: subject)
            subject.onNext("a")
            subject.onNext("b")
            self.writeSequenceToConsole("2", squence: subject)
            subject.onNext("c")
            subject.onNext("d")
            
            //1a,1b,2a,2b,1c,2c,1d,2d
        }
        
        //BehaviorSubject 在有新的订阅的时候 会发送最近发送的一条数据, 如果最近没有发送则发送默认值
        example("BehaviorSubject") {
            let subject = BehaviorSubject<String>.init(value: "z")
            self.writeSequenceToConsole("1", squence: subject)
            subject.onNext("a")
            subject.onNext("b")
            self.writeSequenceToConsole("2", squence: subject)
            subject.onNext("c")
            subject.onCompleted()
            
        }
        
        //Variable 类似于 BehaviorSubject 不同之处在于variable不可以主动发送.Completed 和.Error事件, 他会自动判断订阅结束之后发送.Completed事件
        example("Variable") { 
            let subject = Variable.init("z")
            self.writeSequenceToConsole("1", squence: subject.asObservable() )
            subject.value = "a"
            subject.value = "b"
            self.writeSequenceToConsole("2", squence: subject.asObservable() )
            subject.value = "c"
            
        }
        
        //map 是对每一个元素进行改变
        example("map") { 
            let originalSequence = Observable.of(1,2,3)
            _ = originalSequence.map{$0 * 2}.subscribe{
                print("map = \($0)")
            }
        }
        
        
    }
    
    
    internal func example(description: String, action:() -> ()) {
        print("\n--- \(description) example ---")
        action()
    }
    
    internal func delay(delay: Double, closure:() -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)) ), dispatch_get_main_queue(), closure)
    }
    
    
    let disposeBag = DisposeBag()
    func writeSequenceToConsole<O: ObservableType>(name: String, squence: O) {
        squence.subscribe { e in
            print("Subscription: \(name), event: \(e)")
        }.addDisposableTo(disposeBag)
    }
    
    
    
    
}

