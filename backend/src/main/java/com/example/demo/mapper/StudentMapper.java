package com.example.demo.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.demo.entity.Student;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

// 标记为MyBatis的Mapper接口
@Mapper
public interface StudentMapper extends BaseMapper<Student> {
    // 继承BaseMapper后，自动拥有：增/删/改/查所有方法
    // 例如：selectById、insert、updateById、deleteById等
	@Select("select * from student")
	List<Student>getAllStudent();
}