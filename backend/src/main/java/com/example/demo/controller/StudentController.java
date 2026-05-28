package com.example.demo.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.entity.Student;
import com.example.demo.mapper.StudentMapper;

// 标记为控制器，所有接口路径前缀：/student
@RestController
@RequestMapping("/student")
public class StudentController {

    // 自动注入Mapper（Spring帮我们创建对象，无需new）
    @Autowired
    private StudentMapper studentMapper;

    // ========== GET请求：查询数据 ==========
    /**
     * 1. 查询所有学生（GET请求）
     * 访问路径：http://localhost:8080/student/all
     * 方式：浏览器直接访问 / Postman GET请求
     */
    @GetMapping("/all")
    public List<Student> getAllStudents() {
        // selectList(null)：查询所有数据（MyBatis-Plus内置方法）
        List<Student> rst = studentMapper.getAllStudent();
        System.out.println(rst);
        
        return rst;
    }

    /**
     * 2. 根据ID查询单个学生（GET请求，带参数）
     * 访问路径：http://localhost:8080/student/1
     * 说明：{id}是路径参数，通过@PathVariable获取
     */
    @GetMapping("/{id}")
    public Student getStudentById(@PathVariable Long id) {
        // selectById：根据主键查询
        return studentMapper.selectById(id);
    }

    // ========== POST请求：新增数据 ==========
    /**
     * 新增学生（POST请求）
     * 访问路径：http://localhost:8080/student/add
     * 方式：Postman POST请求，JSON格式传参
     * @RequestBody：接收前端传递的JSON数据，转为Student对象
     */
    @PostMapping("/add")
    public String addStudent(@RequestBody Student student) {
        // insert：新增数据（MyBatis-Plus内置方法）
        int result = studentMapper.insert(student);
        // 新增成功返回1，失败返回0
        return result > 0 ? "新增学生成功！" : "新增学生失败！";
    }
    @GetMapping("/delete/{id}")
    public String delStudent(@PathVariable int id) {
    	   return studentMapper.deleteById(id)>0 ? "删除成功":"删除失败";
    }
}