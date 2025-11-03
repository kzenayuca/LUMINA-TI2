/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.lumina1;

import org.mindrot.jbcrypt.BCrypt;

public class GenerarBcrypt {
    public static void main(String[] args) {
        String passwd = "12345";
        String salt = BCrypt.gensalt(12); // costo 12 (como $2b$12$)
        String hash = BCrypt.hashpw(passwd, salt);
        System.out.println("Salt: " + salt);
        System.out.println("Hash: " + hash);
    }
}

